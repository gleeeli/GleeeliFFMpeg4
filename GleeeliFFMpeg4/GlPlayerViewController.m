//
//  GlPlayerViewController.m
//  GleeeliFFMpeg4
//
//  Created by gleeeli on 2019/7/12.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import "GlPlayerViewController.h"
#import "CommHeader.h"
#include "GlVideoDecoder.h"
#import "GlAudioUnitManager.h"
//视频
#import "GlVideoFrameYUVModel.h"
#import "GlVideoFrameView.h"

#define YUV_Width 720
#define YUV_Height 480

@interface GlPlayerViewController ()
@property (nonatomic, strong) GlAudioUnitManager *audioManager;
@property (nonatomic, strong) GlVideoFrameView *glView;
@end

@implementation GlPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    [self initAudio];
    [self initVideo];
    [self media_decoder_start];
}

- (void)initAudio {
    
    /*音频处理*/
    self.audioManager = [[GlAudioUnitManager alloc] init];
    self.audioManager.samplerate = 48000;
    self.audioManager.channel = 2;
    self.audioManager.mBitsPerChannel = 32;
    self.audioManager.formatFlags = @"float32";
    
    [self.audioManager play];
}

/**
 初始化视频显示
 */
- (void)initVideo {
    NSUInteger widht = YUV_Width;
    NSUInteger height = YUV_Height;
    
    CGFloat glheight = SCREEN_WIDTH / widht * height;
    
    self.glView = [[GlVideoFrameView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, glheight)];
    [self.view addSubview:self.glView];
    
    //decode_video720x480YUV420P
    NSString *inputFilePath = [[NSBundle mainBundle] pathForResource:@"176x144_yuv420p" ofType:@"yuv"];
    const char *yuvFilePath = [inputFilePath UTF8String];
//    unsigned char *buffer = readYUV(yuvFilePath);
}

int get_audio_data_fun(void *inRefCon, const void *audio_frame_bytes,unsigned long length) {
    
    GlPlayerViewController *vc = (__bridge GlPlayerViewController *)inRefCon;
//    printf("得到音频数据：%s\n",audio_frame_bytes);
    NSData *data = [[NSData alloc] initWithBytes:audio_frame_bytes length:length];
    
    [vc.audioManager.queueArray addObject:data];
//    NSString * str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"str:%@",str);
    return 0;
}

int get_video_data_fun(void *inRefCon,const void *video_frame_bytes,unsigned long length) {
    GlPlayerViewController *vc = (__bridge GlPlayerViewController *)inRefCon;
    [vc createYUVFrameData:video_frame_bytes length:length];
    return 0;
}

- (void)createYUVFrameData:(const void *)buffer length:(unsigned long)length{
    NSUInteger ylenght = length*2/3;
    
    NSData *dataY = [NSData dataWithBytes:buffer length:ylenght];
    NSData *dataU = [NSData dataWithBytes:buffer+ylenght length:ylenght/4];
    NSData *dataV = [NSData dataWithBytes:buffer+ylenght*5/4 length:ylenght/4];
    
    GlVideoFrameYUVModel *fmodel = [[GlVideoFrameYUVModel alloc] init];
    fmodel.width = YUV_Width;
    fmodel.height = YUV_Height;
    
    fmodel.lumaY = dataY;
    fmodel.chrominanceU = dataU;
    fmodel.chromaV = dataV;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.glView updateFrameTexture:fmodel];
    });
    
}

/**
 视频解码开始
 */
- (void)media_decoder_start {
    
    NSString *mp4filePath = [[NSBundle mainBundle] pathForResource:@"output_ss6_t10" ofType:@"mp4"];
    const char *mp4path = [mp4filePath UTF8String];
    
    NSString *videofilePath = [kPathDocument stringByAppendingPathComponent:@"movie_video.yuv"];
    const char *video_yuv_path = [videofilePath UTF8String];
    
    unsigned long len = strlen(video_yuv_path)+1;
    char* buf = (char*)malloc(sizeof(char) * len);
    strcpy(buf, video_yuv_path);
    
    const char *video_yuv_path1 = buf;

    NSLog(@"解封装后的video_yuv文件路径：%@",videofilePath);
    
    
    NSString *pcmfilePath = [kPathDocument stringByAppendingPathComponent:@"movie_audioPcm.pcm"];
    const char *pcm1path = [pcmfilePath UTF8String];
    NSLog(@"解码后的pcm文件路径：%@",pcmfilePath);
    
    init_0utput_file(video_yuv_path1, pcm1path);
    testPrint();
    
    start_play_video((__bridge void *)(self), mp4path, get_audio_data_fun, get_video_data_fun);
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
