//
//  GlVideoDecoder.h
//  GleeeliFFMpeg4
//
//  Created by gleeeli on 2019/7/11.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#ifndef GlVideoDecoder_h
#define GlVideoDecoder_h

#include <stdio.h>

struct gl_frame_type {
    double time;//当前帧的显示时间
    double duration;//显示时长
    /**
     * 未知则为：-1
     * 视频则是 enum AVPixelFormat (yuv420p,rgb)(AV_PIX_FMT_YUV420P,AV_PIX_FMT_RGB24)
     * 音频则是：enum AVSampleFormat (mp3,pcm)
     */
    int format;
    /*video only*/
    int width;
    int height;
};

//基本信息 比如时长
/*
 { AV_SAMPLE_FMT_U8,  "u8",    "u8"    },
 { AV_SAMPLE_FMT_S16, "s16be", "s16le" },
 { AV_SAMPLE_FMT_S32, "s32be", "s32le" },
 { AV_SAMPLE_FMT_FLT, "f32be", "f32le" },
 { AV_SAMPLE_FMT_DBL, "f64be", "f64le" }
 */
struct gl_format_type {
    double duration;//秒
    /* audio only */
    int sample_rate; ///< samples per second
    int channels;    ///< number of audio channels
    const char *sample_fmt_str;//u8 s16be
    int mBitsPerChannel;
};

typedef int (*GVDFType)(void *inRefCon,const void *video_frame_bytes,unsigned long length,struct gl_frame_type frame_info);
typedef int (*GADFType)(void *inRefCon,const void *audio_frame_bytes,unsigned long length,struct gl_frame_type frame_info);

//通知状态
typedef void (*GlSCFType)(void *inRefCon,int status);
//获取到基本信息通知
typedef void (*GlGFIFun)(void *inRefCon,struct gl_format_type info);

/**
 返回当前解码状态
 */
int gl_get_cur_status(void);

/**
 注册需要的通知函数
 
 @param status_change_notification 状态改变通知
 */
void gl_register_funs(GADFType get_audio_data,GVDFType get_video_data,GlSCFType status_change_notification,GlGFIFun get_format_info);

/**
 初始化基本信息，以及打开解码器

 @param target 往后需要返回的对象
 @param videofilePaht 视频地址
 */
int gl_init_and_open_decoder(void *target,const char *videofilePaht);

//测试用的，保存pcm和yuv文件
int gl_test_init_and_open_decoder_save_file(void *target,const char *videofilePaht,const char *yuvfilePath,const char *pcmfilePaht);

//暂停
void gl_pause_decoder(void);
//开始
void gl_start_decoder(void);

//从指定的秒数开始解码
void gl_decoder_seek(double seconds);
/**
 解码结束
 */
void gl_exit_decoder(void);
#endif /* GlVideoDecoder_h */
