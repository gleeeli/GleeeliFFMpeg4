//
//  GlVideoDecoder.h
//  GleeeliFFMpeg4
//
//  Created by 小柠檬 on 2019/7/11.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#ifndef GlVideoDecoder_h
#define GlVideoDecoder_h

#include <stdio.h>
void init_0utput_file(const char *out_yuv_path,const char *out_pcm_path);
void testPrint();
int start_play_video(void *target,const char *filePaht,int (*get_audio_data)(void *inRefCon,const void *audio_frame_bytes,unsigned long lenght),int (*get_video_data)(void *inRefCon,const void *video_frame_bytes,unsigned long lenght));
#endif /* GlVideoDecoder_h */
