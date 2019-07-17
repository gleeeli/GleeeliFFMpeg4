//
//  GlVideoFrameView.h
//  GlOpenGlESDemo
//
//  Created by 小柠檬 on 2019/7/9.
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
@end

