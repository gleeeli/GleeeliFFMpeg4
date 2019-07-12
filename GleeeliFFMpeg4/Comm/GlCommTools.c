//
//  GlCommTools.c
//  GleeeliFFMpeg4
//
//  Created by 小柠檬 on 2019/7/12.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#include "GlCommTools.h"
/*
 char * strrchr(const char *str, int c); :函数用于查找某字符在字符串中最后一次出现的位置
 char *strchr(const char *str, int c)：在一个串中查找给定字符的第一个匹配之处。函数原型为
 */

//截取字符串
char* substring(char* ch,int pos,int length)
{
    //定义字符指针 指向传递进来的ch地址
    char* pch=ch;
    //通过calloc来分配一个length长度的字符数组，返回的是字符指针。
    char* subch=(char*)calloc(sizeof(char),length+1);
    int i;
    //只有在C99下for循环中才可以声明变量，这里写在外面，提高兼容性。
    pch=pch+pos;
    //是pch指针指向pos位置。
    for(i=0;i<length;i++)
    {
        subch[i]=*(pch++);
        //循环遍历赋值数组。
    }
    subch[length]='\0';//加上字符串结束符。
    return subch;       //返回分配的字符数组地址。
}

//获取路径的文件名
void *get_filename(char *p)
{
    char ch = '/';
    char *q = strrchr(p,ch) + 1;
    
    return q;
}

//获取路径的最后一个文件夹的路径
void *get_folder_path(char *p)
{
    char ch = '/';
    char *q = strrchr(p,ch) + 1;
    int nlenght = (int)(q - p - 1);
    char *path = substring(p, 0, nlenght);
    
    return path;
}
