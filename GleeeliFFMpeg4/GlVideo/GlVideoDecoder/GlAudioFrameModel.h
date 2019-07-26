//
//  GlAudioFrameModel.h
//  GleeeliFFMpeg4
//
//  Created by gleeeli on 2019/7/15.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlAudioFrameModel : NSObject
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) double time;
@property (nonatomic, assign) double duration;
@end
