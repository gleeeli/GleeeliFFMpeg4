//
//  ResampleAudio.h
//  GleeeliFFMpeg4
//
//  Created by gleeeli on 2019/6/20.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ResampleAudio : NSObject
- (void)pcmResample:(NSString *)mp3filePath pcmfilePath:(NSString *)pcmfilePath;
@end

NS_ASSUME_NONNULL_END
