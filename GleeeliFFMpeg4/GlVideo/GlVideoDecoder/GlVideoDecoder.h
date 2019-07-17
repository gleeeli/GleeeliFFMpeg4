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
};

//基本信息 比如时长
struct gl_format_type {
    double duration;//秒
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
void gl_register_funs(GlSCFType status_change_notification,GlGFIFun get_format_info);

int start_play_video(void *target,const char *filePaht,GADFType get_audio_data,GVDFType get_video_data);

int start_play_video_and_save_file(void *target,const char *videofilePaht,const char *yuvfilePath,const char *pcmfilePaht,GADFType get_audio_data,GVDFType get_video_data);
#endif /* GlVideoDecoder_h */
