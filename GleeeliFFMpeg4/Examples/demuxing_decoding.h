//
//  demuxing_decoding.h
//  GleeeliFFMpeg4
//
//  Created by 小柠檬 on 2019/6/24.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#ifndef demuxing_decoding_h
#define demuxing_decoding_h

#include <stdio.h>

/**
 解封装
 
 @param filename 源文件
 @param out_h264File 码流h264
 @param out_videofile 纯视频文件yuv
 @param out_audiofile 纯音频文件 aac
 */
int start_main_demuxing_decoding (const char *filename,const char *out_h264File, const char *out_videofile,const char *out_audiofile);

#endif /* demuxing_decoding_h */
