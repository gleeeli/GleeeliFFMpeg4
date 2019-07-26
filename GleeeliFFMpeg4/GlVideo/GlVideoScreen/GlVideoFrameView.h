//
//  GlVideoFrameView.h
//  GlOpenGlESDemo
//
//  Created by gleeeli on 2019/7/9.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlVideoFrameYUVModel.h"
#import "GlVideoFrameRGBModel.h"

@interface GlVideoFrameView : UIView
@property (atomic, assign) double mainClockTime;
@property (atomic, assign) double mainDuration;
/**
 更新一帧数据
 */
- (void)updateFrameTexture:(GlVideoFrameModel *)frameModel;

/**
 往缓冲数组增加帧
 */
- (void)addFrame:(GlVideoFrameModel *)model;

/**
 开始显示缓存的帧数据
 */
- (void)startShowFrame;

/**
 暂停显示缓存的帧数据
 */
- (void)pauseShowFrame;

/**
 清楚缓存
 */
- (void)clearCache;
@end

