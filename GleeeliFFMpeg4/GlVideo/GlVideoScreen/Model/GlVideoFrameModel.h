//
//  GlVideoFrameModel.h
//  GlOpenGlESDemo
//
//  Created by 小柠檬 on 2019/7/10.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlVideoFrameModel : NSObject
@property (nonatomic) NSUInteger width;//帧图片的宽
@property (nonatomic) NSUInteger height;
@property (nonatomic, assign) float time;//当前帧的显示时间
@property (nonatomic, assign) float duration;//持续时间
@end
