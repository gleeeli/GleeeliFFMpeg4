//
//  GlVideoDecoder.c
//  GleeeliFFMpeg4
//
//  Created by 小柠檬 on 2019/7/11.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#include "GlVideoDecoder.h"
#include <libavutil/imgutils.h>
#include <libavutil/samplefmt.h>
#include <libavutil/timestamp.h>
#include <libavformat/avformat.h>
#include "GlCommTools.h"

static AVFormatContext *fmt_ctx = NULL;
static AVCodecContext *video_dec_ctx = NULL, *audio_dec_ctx;
//static int width, height;
//static enum AVPixelFormat pix_fmt;//像素格式
static AVStream *video_stream = NULL, *audio_stream = NULL;
static const char *video_src_filePath = NULL;//视频源文件路径
static const char *video_yuv_filePath = NULL;
static const char *audio_pcm_filePath = NULL;
static FILE *audio_pcm_file = NULL;
//static uint8_t *video_dst_data[4] = {NULL};
//static int      video_dst_linesize[4];
//static int video_dst_bufsize;
static int video_stream_idx = -1, audio_stream_idx = -1;
static AVFrame *frame = NULL;
static AVPacket pkt;
static int refcount = 0;//理解：控制多次引用内存，不用反复初始化AVFRame
/*
 状态
 大于等于500的错是必须停止的，或需要重新初始化
 -1为出错
 0:未开始
 -500:发送packet错误
 -501:接收frame出错
 -502:获取音频帧采样大小时出错
 */
static int status = 0;


void init_0utput_file(const char *out_yuv_path,const char *out_pcm_path) {
    video_yuv_filePath = out_yuv_path;
    audio_pcm_filePath = out_pcm_path;
    
    audio_pcm_file = fopen(out_pcm_path, "wb");
    if (!audio_pcm_file) {
        status = 400;
    }
}

void testPrint() {
    printf("video:%s,\naudio:%s\n",video_yuv_filePath,audio_pcm_filePath);
}

/**
 将每一行的数据写入
 */
static void write_yuv_data(unsigned char *buf,int wrap,int xsize, int ysize, FILE *f){
    int i;
    //依次写入每一行数据
    for (i = 0; i < ysize; i++)
        fwrite(buf + i * wrap, 1, xsize, f);
}

/**
 报错为yuv420p格式文件
 
 @param data yuv数组
 @param linesize 每行大小数组
 @param xsize 宽
 @param ysize 高
 @param filename 保存文件名
 */
static void yuv_save(uint8_t *data[], int linesize[], int xsize, int ysize,
                     char *filename)
{
    FILE *f;
    f = fopen(filename,"w");
    write_yuv_data(data[0], linesize[0], xsize, ysize, f);
    write_yuv_data(data[1], linesize[1], xsize/2, ysize/2, f);
    write_yuv_data(data[2], linesize[2], xsize/2, ysize/2, f);
    fclose(f);
}

static void decode_packet(AVCodecContext *dec_ctx, AVFrame *frame, AVPacket *pkt) {
    int ret;
    ret = avcodec_send_packet(dec_ctx, pkt);
    if (ret < 0) {
        status = -500;
        fprintf(stderr, "Error sending a packet for decoding\n");
        return;
    }
    while (ret >= 0) {
        //获取一帧
        ret = avcodec_receive_frame(dec_ctx, frame);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)//当前包(packet)里的所有帧读取完成
            return;
        else if (ret < 0) {
            fprintf(stderr, "Error during decoding\n");
            status = -501;
            return;
        }
        
        if(pkt->stream_index == video_stream_idx){//处理视频YUV
            printf("frame number %3d\n", dec_ctx->frame_number);
            printf("widht:%d,height:%d\n",frame->width,frame->height);
            fflush(stdout);
            
            if (video_yuv_filePath) {//需要保存到本地
                char filename[1024];
                char *fileName = get_filename((char *)video_yuv_filePath);
                char *folderPaht = get_folder_path((char *)video_yuv_filePath);
                
                //格式化字符串到buf中，也就是输出文件后部拼接帧序号
                snprintf(filename, sizeof(filename), "%s/%d-%s", folderPaht, dec_ctx->frame_number, fileName);
                yuv_save(frame->data, frame->linesize, frame->width, frame->height, filename);
            }
            
        }else if(pkt->stream_index == audio_stream_idx){//处理音频PCM
            int i,
            ch,//通道数
            data_size;//采样的大小
            
            //获取每个采样的大小
            data_size = av_get_bytes_per_sample(dec_ctx->sample_fmt);
            if (data_size < 0) {
                status = -502;
                fprintf(stderr, "Failed to calculate data size\n");
                return;
            }
            fprintf(stderr, "avcodec_receive_frame ret:%d data_size:%d \n",ret,data_size);
            fprintf(stderr, "参数：nb_samples:%d sample_fmt:%d channels:%d sample_rate：%d   linesize0:%d linesize1:%d channels:%d\n",frame->nb_samples,dec_ctx->sample_fmt,dec_ctx->channels,dec_ctx->sample_rate,frame->linesize[0],frame->linesize[1],frame->channels);
            
            //nb_samples:当前帧的音频采样个数？
            if (audio_pcm_file) {
                //pcm数据写入本地文件
                for (i = 0; i < frame->nb_samples; i++)
                    for (ch = 0; ch < dec_ctx->channels; ch++)
                        fwrite(frame->data[ch] + data_size*i, 1, data_size, audio_pcm_file);
            }
            
        }
        
    }
}

static int open_codec_context(int *stream_idx,
                              AVCodecContext **dec_ctx, AVFormatContext *fmt_ctx, enum AVMediaType type)
{
    int ret, stream_index;
    AVStream *st;
    AVCodec *dec = NULL;
    AVDictionary *opts = NULL;
    //流类型枚举转字符串
    const char * type_str = av_get_media_type_string(type);
    
    //找出视频流或音频流的id号
    ret = av_find_best_stream(fmt_ctx, type, -1, -1, NULL, 0);
    if (ret < 0) {
        fprintf(stderr, "Could not find %s stream in input file '%s'\n",type_str, video_src_filePath);
        return ret;
    } else {
        stream_index = ret;
        st = fmt_ctx->streams[stream_index];
        //找到解码器，比如是h264还是MPEG-1的解码器
        dec = avcodec_find_decoder(st->codecpar->codec_id);
        if (!dec) {
            fprintf(stderr, "Failed to find %s codec，codec_id:%d\n",type_str,st->codecpar->codec_id);
            return AVERROR(EINVAL);
        }
        
        //为解码器分配上下文
        *dec_ctx = avcodec_alloc_context3(dec);
        if (!*dec_ctx) {
            fprintf(stderr, "Failed to allocate the %s codec context\n",type_str);
            return AVERROR(ENOMEM);
        }
        //将流中的参数拷贝进解码器上下文
        if ((ret = avcodec_parameters_to_context(*dec_ctx, st->codecpar)) < 0) {
            fprintf(stderr, "Failed to copy %s codec parameters to decoder context\n",type_str);
            return ret;
        }
        /*根据是否使用引用计数初始化解码器，
         另外还可设置一些编码速度或者质量相关的参数，例如使用libx264编码的时候，“preset”，“tune”等
         opts也可置空NULL
         */
        av_dict_set(&opts, "refcounted_frames", refcount ? "1" : "0", 0);
        if ((ret = avcodec_open2(*dec_ctx, dec, &opts)) < 0) {
            fprintf(stderr, "Failed to open %s codec\n",type_str);
            return ret;
        }
        *stream_idx = stream_index;
    }
    return 0;
}

int start_play_video(const char *filePaht) {
    int ret = 0;
    video_src_filePath = filePaht;
    //打开文件 初始化格式上下文
    if (avformat_open_input(&fmt_ctx, video_src_filePath, NULL, NULL) < 0) {
        fprintf(stderr, "Could not open source file %s\n", video_src_filePath);
        return -1;
    }
    
    //检索流信息
    if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
        fprintf(stderr, "Could not find stream information\n");
        return -1;
    }
    
    //打开视频解码器,获取视频流id（video_stream_idx）,获取解码器上下文(video_dec_ctx)
    if (open_codec_context(&video_stream_idx, &video_dec_ctx, fmt_ctx, AVMEDIA_TYPE_VIDEO) >= 0) {
        video_stream = fmt_ctx->streams[video_stream_idx];
        
    }
    //打开音频解码器
    if (open_codec_context(&audio_stream_idx, &audio_dec_ctx, fmt_ctx, AVMEDIA_TYPE_AUDIO) >= 0) {
        audio_stream = fmt_ctx->streams[audio_stream_idx];
    }
    
    av_dump_format(fmt_ctx, 0, video_src_filePath, 0);
    
    frame = av_frame_alloc();
    if (!frame) {
        fprintf(stderr, "Could not allocate frame\n");
        ret = AVERROR(ENOMEM);
        goto end;
    }
    
    av_init_packet(&pkt);
    pkt.data = NULL;
    pkt.size = 0;
    
    //获取每帧数据包（pkt），此时每个包可能还包含着多个帧
    while (av_read_frame(fmt_ctx, &pkt) >= 0) {
        if(pkt.stream_index == video_stream_idx){
            decode_packet(video_dec_ctx,frame,&pkt);
        }else if(pkt.stream_index == audio_stream_idx){
            decode_packet(audio_dec_ctx,frame,&pkt);
        }
        
        //发生意外结束程序
        if (status >= 500) {
            fprintf(stderr, "Error exit status:%d\n",status);
            goto end;
            break;
        }
    }
    
end:
    avcodec_free_context(&video_dec_ctx);
    avcodec_free_context(&audio_dec_ctx);
    avformat_close_input(&fmt_ctx);

    if (audio_pcm_file)
        fclose(audio_pcm_file);
    av_frame_free(&frame);
    return ret < 0;
}