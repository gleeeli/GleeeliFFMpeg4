//
//  GlPlayerViewController.m
//  GleeeliFFMpeg4
//
//  Created by 小柠檬 on 2019/7/12.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import "GlPlayerViewController.h"
#include "GlVideoDecoder.h"
#import "GlAudioUnitManager.h"
#import "CommHeader.h"

@interface GlPlayerViewController ()
@property (nonatomic, strong) GlAudioUnitManager *audioManager;
@end

@implementation GlPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.audioManager = [[GlAudioUnitManager alloc] init];
    self.audioManager.samplerate = 48000;
    self.audioManager.channel = 2;
    self.audioManager.mBitsPerChannel = 32;
    self.audioManager.formatFlags = @"float32";
    
    [self.audioManager play];
    
    [self video_decoder];
}

int get_audio_data_fun(void *inRefCon, const void *audio_frame_bytes,unsigned long lenght) {
    
    GlPlayerViewController *vc = (__bridge GlPlayerViewController *)inRefCon;
//    printf("得到音频数据：%s\n",audio_frame_bytes);
    NSData *data = [[NSData alloc] initWithBytes:audio_frame_bytes length:lenght];
    
    [vc.audioManager.queueArray addObject:data];
//    NSString * str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"str:%@",str);
    return 0;
}

int get_video_data_fun(void *inRefCon,const void *video_frame_bytes,unsigned long lenght) {
    
    return 0;
}

- (void)video_decoder {
    
    NSString *mp4filePath = [[NSBundle mainBundle] pathForResource:@"output_ss6_t10" ofType:@"mp4"];
    const char *mp4path = [mp4filePath UTF8String];
    
    NSString *videofilePath = [kPathDocument stringByAppendingPathComponent:@"movie_video.yuv"];
    const char *videopath = [videofilePath UTF8String];
    NSLog(@"解封装后的video_yuv文件路径：%@",videofilePath);
    
    
    NSString *pcmfilePath = [kPathDocument stringByAppendingPathComponent:@"movie_audioPcm.pcm"];
    const char *pcmpath = [pcmfilePath UTF8String];
    NSLog(@"解码后的pcm文件路径：%@",pcmfilePath);
    
    init_0utput_file(videopath, pcmpath);
    testPrint();
    
    start_play_video((__bridge void *)(self),mp4path,get_audio_data_fun,get_video_data_fun);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
