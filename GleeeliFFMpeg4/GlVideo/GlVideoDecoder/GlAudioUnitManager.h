//
//  GlAudioUnitManager.h
//  GleeeliFFMpeg4
//
//  Created by gleeeli on 2019/7/12.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlAudioFrameModel.h"

@protocol GlPlayeAudioDelegate <NSObject>
@optional
- (void)playAudioEnd;
- (void)curPlayModel:(GlAudioFrameModel *)fmodel;

@end

@interface GlAudioUnitManager : NSObject
@property (nonatomic, assign) unsigned int samplerate;
@property (nonatomic, assign) unsigned int nb_samples;//每个packet包含帧的数量
@property (nonatomic, assign) unsigned int channel;//通道数
@property (nonatomic, assign) unsigned int mBitsPerChannel;//每个采样数据的位数
@property (nonatomic, assign) NSString *formatFlags;//int16 float32

//Big-Endian,Little-Endian采用大端方式进行数据存放符合人类的正常思维，而采用小端方式进行数据存放利于计算机处理
@property (nonatomic, assign) BOOL isBigEndian;//是否大端  高字节在低地址, 低字节在高地址

@property (nonatomic, weak) id<GlPlayeAudioDelegate> delegate;
@property (atomic, strong) NSMutableArray<GlAudioFrameModel *> *queueArray;
@property (atomic, assign) int decoderStatus;//解码状态

- (void)play;
- (void)stop;

/**
 清楚缓存
 */
- (void)clearCache;
@end


