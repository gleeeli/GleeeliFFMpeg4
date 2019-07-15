//
//  ResampleAudio.m
//  GleeeliFFMpeg4
//
//  Created by gleeeli on 2019/6/20.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import "ResampleAudio.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libavutil/frame.h>
#include <libavutil/mem.h>
#include <libavcodec/avcodec.h>

#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
#import "CommHeader.h"

@implementation ResampleAudio
- (void)pcmResample:(NSString *)mp3filePath pcmfilePath:(NSString *)pcmfilePath{
    
    const char *inputFilePath = [mp3filePath UTF8String];
    const char *outputAudioFilePath = [pcmfilePath UTF8String];
    
    FILE *outAudioFile = fopen(outputAudioFilePath, "wb");
    int ret = 0;
    int channels = 1;
    int out_sample_rate = 44100;
    
    AVFormatContext *formatCtx = NULL;
    AVCodec *audioCodec = NULL;
    AVCodecContext *audioCodecCtx = NULL;
    AVCodecParameters *audioCodecParams = NULL;
    AVFrame *audioInFrame = NULL;
    AVPacket packet;
    AVFrame *audioOutFrame = NULL;
    //设置输出采样格式
    enum AVSampleFormat outPutResampleFormat = AV_SAMPLE_FMT_S16;//AV_SAMPLE_FMT_S32
    struct SwrContext *swrContext = NULL;
    
    av_register_all();
    if (avformat_open_input(&formatCtx, inputFilePath, NULL, NULL) != 0) {
        printf("打开文件失败");
        exit(0);
    }
    if (avformat_find_stream_info(formatCtx, NULL) != 0) {
        printf("获取文件信息失败");
        exit(0);
    }
    
    int stream_audio_index = -1;
    
    for (int i = 0; i < formatCtx->nb_streams; i++) {
        if (formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            stream_audio_index = i;
        }
    }
    
    if (stream_audio_index == -1) {
        printf("找不到音频流");
        exit(0);
    }
    
    audioCodecParams = formatCtx->streams[stream_audio_index]->codecpar;
    audioCodec = avcodec_find_decoder(audioCodecParams->codec_id);
    if (!audioCodec) {
        printf("找不到音频解码器\n");
        exit(0);
    }
    audioCodecCtx = avcodec_alloc_context3(audioCodec);
    if (audioCodecCtx) {
        //将流中的参数拷贝进解码器
        int ret = avcodec_parameters_to_context(audioCodecCtx, audioCodecParams);
        if (ret < 0) {
            printf("avcodec_parameters_to_context 音频出错");
            exit(0);
        }
    }
    if (avcodec_open2(audioCodecCtx, audioCodec, NULL)) {
        printf("打开音频解码器失败");
        exit(0);
    }
    
    av_init_packet(&packet);
    av_dump_format(formatCtx, 0, inputFilePath, 0);
    audioOutFrame = av_frame_alloc();
    audioInFrame = av_frame_alloc();
    
    //这个函数会考虑音频分片（平面），返回能存放全部通道的所有样本数量的音频数据的buffer大小
    //最后一个参数align代表是否对齐，传0默认缓存大小按32的倍数对齐，看源码便知
    int out_buffer_size = av_samples_get_buffer_size(NULL, channels, 1024, outPutResampleFormat, 0);
    uint8_t *audio_out_buffer = (uint8_t *)av_malloc(out_buffer_size);
    audioOutFrame->nb_samples = 1024;//每一帧的采样个数
    
    ret = avcodec_fill_audio_frame(audioOutFrame, channels, outPutResampleFormat, audio_out_buffer, out_buffer_size, 0);
    
    if (ret < 0) {
        printf("av_samples_fill_arrays failed");
        exit(0);
    }
    
    //设置重采样的输入和输出采样率和采样格式
    int64_t out_channel_layout = AV_CH_LAYOUT_MONO; // 单声道MONO 双声道 STEREO
    swrContext = swr_alloc_set_opts(NULL, out_channel_layout, outPutResampleFormat, out_sample_rate, audioCodecCtx->channel_layout, audioCodecCtx->sample_fmt, audioCodecCtx->sample_rate, 0, NULL);
    swr_init(swrContext);
    
    int audio_frame_cnt = 0;
    
    while (av_read_frame(formatCtx, &packet) >= 0) {
        /// 音频流
        if (packet.stream_index == stream_audio_index) {
            ret = avcodec_send_packet(audioCodecCtx, &packet);
            if (ret != 0) {
                printf("avcodec_send_packet failed");
                exit(0);
            }
            ret = avcodec_receive_frame(audioCodecCtx, audioInFrame);
            if (ret != 0) {
                printf("avcodec_send_packet failed");
                exit(0);
            }
            
            //mp3采样格式一定是分平面，这里不考虑else
            if (av_sample_fmt_is_planar(audioInFrame->format)) {//如果是分平面（分片）数据，为每一声道分配一个fifo（先进先出队列），单独存储各平面数据
                int out_samples = swr_convert(swrContext, audioOutFrame->data, audioOutFrame->nb_samples, (const uint8_t **)audioInFrame->data, audioInFrame->nb_samples);
                printf("decode audio frame: %d out_samples: %d \n",audio_frame_cnt,out_samples);
                fwrite(audioOutFrame->data[0], 1, audioOutFrame->linesize[0], outAudioFile);
                audio_frame_cnt++;
            }
        }
        av_packet_unref(&packet);
    }
    printf("resample success \n");
    avcodec_free_context(&audioCodecCtx);
    avformat_close_input(&formatCtx);
    swr_free(&swrContext);
}
@end
