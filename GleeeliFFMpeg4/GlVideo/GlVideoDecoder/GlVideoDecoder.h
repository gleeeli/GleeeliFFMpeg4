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
void init_0utput_file(const char *out_yuv_path,const char *out_pcm_path);
void testPrint();

typedef int (*GVDType)(void *inRefCon,const void *video_frame_bytes,unsigned long length);
typedef int (*GADType)(void *inRefCon,const void *audio_frame_bytes,unsigned long length);

int start_play_video(void *target,const char *filePaht,GADType get_audio_data,GVDType get_video_data);
#endif /* GlVideoDecoder_h */
