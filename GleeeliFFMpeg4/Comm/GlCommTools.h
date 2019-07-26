//
//  GlCommTools.h
//  GleeeliFFMpeg4
//
//  Created by gleeeli on 2019/7/12.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#ifndef GlCommTools_h
#define GlCommTools_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//截取字符串
char* substring(char* ch,int pos,int length);
//获取路径的最后一个文件夹的路径
void *get_folder_path(char *p);
//获取路径的文件名
void *get_filename(char *p);
#endif /* GlCommTools_h */
