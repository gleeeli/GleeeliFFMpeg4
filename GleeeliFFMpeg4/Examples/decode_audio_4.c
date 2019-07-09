//
//  decode_audio_4.c
//  GleeeliFFMpeg4
//
//  Created by 小柠檬 on 2019/6/20.
//  Copyright © 2019 gleeeli. All rights reserved.
//

/**
 * 4.0版本解码音频案列
 */

#include "decode_audio_4.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libavutil/frame.h>
#include <libavutil/mem.h>
#include <libavcodec/avcodec.h>

#include <libavformat/avformat.h>

#define AUDIO_INBUF_SIZE 20480

#define AUDIO_REFILL_THRESH 4096
static void decode(AVCodecContext *dec_ctx, AVPacket *pkt, AVFrame *frame,
                   FILE *outfile)
{
    int i, ch;
    int ret, data_size;
    /* send the packet with the compressed data to the decoder */
    ret = avcodec_send_packet(dec_ctx, pkt);
    if (ret < 0) {
        fprintf(stderr, "Error submitting the packet to the decoder\n");
        exit(1);
        return;
    }
    fprintf(stderr, "avcodec_send_packet ret:%d \n",ret);
    /* read all the output frames (in general there may be any number of them */
    while (ret >= 0) {
        ret = avcodec_receive_frame(dec_ctx, frame);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
            return;
        else if (ret < 0) {
            fprintf(stderr, "Error during decoding\n");
            exit(1);
        }
        //获取每个采样的大小
        data_size = av_get_bytes_per_sample(dec_ctx->sample_fmt);
        if (data_size < 0) {
            /* This should not occur, checking just for paranoia */
            fprintf(stderr, "Failed to calculate data size\n");
            exit(1);
        }
        fprintf(stderr, "avcodec_receive_frame ret:%d data_size:%d \n",ret,data_size);
        fprintf(stderr, "参数：nb_samples:%d sample_fmt:%d channels:%d sample_rate：%d \n",frame->nb_samples,dec_ctx->sample_fmt,dec_ctx->channels,dec_ctx->sample_rate);
        
        //nb_samples:音频的一个AVFrame中可能包含多个音频帧，在此标记包含了几个
        for (i = 0; i < frame->nb_samples; i++)
            for (ch = 0; ch < dec_ctx->channels; ch++)
                fwrite(frame->data[ch] + data_size*i, 1, data_size, outfile);
    }
}

/**
 解码音频
 
 @param outfilename pcm文件路径
 @param filename 音频文件如mp3
 */
int start_main_decode_audio4(const char *outfilename, const char *filename)
{
//    av_register_all();
//    avcodec_register_all();
    const AVCodec *codec;
    AVCodecContext *c= NULL;
    AVCodecParserContext *parser = NULL;
    int len, ret;
    FILE *f, *outfile;
    uint8_t inbuf[AUDIO_INBUF_SIZE + AV_INPUT_BUFFER_PADDING_SIZE];// + AV_INPUT_BUFFER_PADDING_SIZE
    uint8_t *data;
    size_t   data_size;
    AVPacket *pkt;
    AVFrame *decoded_frame = NULL;

    pkt = av_packet_alloc();
    /* find the MPEG audio decoder */
    codec = avcodec_find_decoder(AV_CODEC_ID_MP2);
    if (!codec) {
        fprintf(stderr, "Codec not found\n");
        exit(1);
    }
    parser = av_parser_init(codec->id);
    if (!parser) {
        fprintf(stderr, "Parser not found\n");
        exit(1);
    }
    c = avcodec_alloc_context3(codec);
    if (!c) {
        fprintf(stderr, "Could not allocate audio codec context\n");
        exit(1);
    }
    /* open it */
    if (avcodec_open2(c, codec, NULL) < 0) {
        fprintf(stderr, "Could not open codec\n");
        exit(1);
    }
    f = fopen(filename, "rb");
    if (!f) {
        fprintf(stderr, "Could not open %s\n", filename);
        exit(1);
    }
    outfile = fopen(outfilename, "wb");
    if (!outfile) {
        av_free(c);
        exit(1);
    }
    /* decode until eof */
    data      = inbuf;
    //从文件流种获取指定大小的inbuf
    data_size = fread(inbuf, 1, AUDIO_INBUF_SIZE, f);
    
    
    while (data_size > 0) {
        if (!decoded_frame) {
            if (!(decoded_frame = av_frame_alloc())) {
                fprintf(stderr, "Could not allocate audio frame\n");
                exit(1);
            }
        }
        //获取AVPacket的data和size，跟av_read_frame类似。
        //parser用于从raw data中parse出packet
        //输入必须是只包含视频编码数据“裸流”（例如H.264、HEVC码流文件），而不能是包含封装格式的媒体数据（例如AVI、MKV、MP4）。
        ret = av_parser_parse2(parser, c, &pkt->data, &pkt->size,
                               data, data_size,//本地buff的和其大小
                               AV_NOPTS_VALUE, AV_NOPTS_VALUE, 0);
        if (ret < 0) {
            fprintf(stderr, "Error while parsing\n");
            exit(1);
        }
        //本次去读数据长度ret，下次指针位置后移
        data      += ret;
        data_size -= ret;
        if (pkt->size)
            decode(c, pkt, decoded_frame, outfile);
        if (data_size < AUDIO_REFILL_THRESH) {
            memmove(inbuf, data, data_size);
            data = inbuf;
            len = fread(data + data_size, 1,
                        AUDIO_INBUF_SIZE - data_size, f);
            if (len > 0)
                data_size += len;
        }
    }
    /* flush the decoder */
    pkt->data = NULL;
    pkt->size = 0;
    decode(c, pkt, decoded_frame, outfile);
    fclose(outfile);
    fclose(f);
    avcodec_free_context(&c);
    av_parser_close(parser);
    av_frame_free(&decoded_frame);
    av_packet_free(&pkt);
    return 0;
}


/*
 打印的日志：
 avcodec_send_packet ret:0
 avcodec_receive_frame ret:0 data_size:2
 参数：nb_samples:1152 sample_fmt:6 channels:2 sample_rate：44100
 */
