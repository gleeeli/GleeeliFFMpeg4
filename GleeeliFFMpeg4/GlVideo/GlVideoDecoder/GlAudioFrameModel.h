//
//  GlAudioFrameModel.h
//  GleeeliFFMpeg4
//
//  Created by 小柠檬 on 2019/7/15.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlAudioFrameModel : NSObject
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) float time;
@property (nonatomic, assign) float duration;
@end
