//
//  decode_video.h
//  GleeeliFFMpeg4
//
//  Created by 小柠檬 on 2019/6/24.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#ifndef decode_video_h
#define decode_video_h

#include <stdio.h>

/**
 解码
 
 @param filename 码流文件h264或者mpeg-1
 @param outfilename yuv文件
 */
int start_main_decode_video(const char *filename, const char *outfilename);

#endif /* decode_video_h */
