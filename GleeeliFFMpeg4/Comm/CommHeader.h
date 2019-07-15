//
//  CommHeader.h
//  SFFmpegIOSStreamer
//
//  Created by zqh on 2018/6/7.
//  Copyright © 2018年 Lei Xiaohua. All rights reserved.
//

#ifndef CommHeader_h
#define CommHeader_h

#define RTMPServiceAddress @"rtmp://192.168.0.101:1935/zbcs/room"

//获取沙盒 Document
#define kPathDocument [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]

//获取沙盒 Cache
#define kPathCache [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]

#import <VideoToolbox/VideoToolbox.h>
#import <AudioToolbox/AudioToolbox.h>

//！屏幕宽度
#define SCREEN_WIDTH  [[UIScreen mainScreen] bounds].size.width
//！屏幕高度
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

#endif /* CommHeader_h */
