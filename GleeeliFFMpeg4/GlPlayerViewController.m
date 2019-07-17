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
#import "GlControlView.h"

#define YUV_Width 720
#define YUV_Height 480

@interface GlPlayerViewController ()<GlPlayeAudioDelegate,GlControlViewDelegate>
@property (nonatomic, strong) GlAudioUnitManager *audioManager;
@property (nonatomic, strong) GlVideoFrameView *glView;
@property (nonatomic, strong) GlControlView *cview;
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
    self.audioManager.delegate = self;
    
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
    
    //测试直接显示用的文件： decode_video720x480YUV420P
//    NSString *inputFilePath = [[NSBundle mainBundle] pathForResource:@"176x144_yuv420p" ofType:@"yuv"];
//    const char *yuvFilePath = [inputFilePath UTF8String];
//    unsigned char *buffer = readYUV(yuvFilePath);
    
    CGFloat cvH = 44;
    CGFloat cvY = glheight - cvH;
    GlControlView *cview = [[GlControlView alloc] initWithFrame:CGRectMake(0, cvY, self.glView.frame.size.width, 44)];
    self.cview = cview;
    cview.delegate = self;
    cview.value = 0;
    cview.minValue = 0.f;
    cview.currentTime = @"00:00";
    cview.totalTime = @"00:00";
//    self.controlView.totalTime = [self convertTime:second];
//    self.controlView.minValue = 0;
//    self.controlView.maxValue = second;
    [self.glView addSubview:cview];
}

#pragma mark 解码通知
//得到时长等信息
void gl_get_format_info_fun(void *inRefCon,struct gl_format_type info) {
    GlPlayerViewController *vc = (__bridge GlPlayerViewController *)inRefCon;
    dispatch_async(dispatch_get_main_queue(), ^{
        vc.cview.maxValue = info.duration;
        
    });
    
}

//状态改变通知
void gl_status_chang_notification(void *inRefCon,int status) {
    printf("状态改变通知:%d",status);
    GlPlayerViewController *vc = (__bridge GlPlayerViewController *)inRefCon;
    vc.audioManager.decoderStatus = status;
}

//音频解码获得数据
int get_audio_data_fun(void *inRefCon, const void *audio_frame_bytes,unsigned long length,struct gl_frame_type frame_info) {
    
    GlPlayerViewController *vc = (__bridge GlPlayerViewController *)inRefCon;
//    printf("得到音频数据：%s\n",audio_frame_bytes);
    NSData *data = [[NSData alloc] initWithBytes:audio_frame_bytes length:length];
    GlAudioFrameModel *model = [[GlAudioFrameModel alloc] init];
    model.time = frame_info.time;
    model.duration = frame_info.duration;
    model.data = data;
    
    [vc.audioManager.queueArray addObject:model];
//    NSString * str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"str:%@",str);
    return 0;
}

int get_video_data_fun(void *inRefCon,const void *video_frame_bytes,unsigned long length,struct gl_frame_type frame_info) {
    GlPlayerViewController *vc = (__bridge GlPlayerViewController *)inRefCon;
    [vc createYUVFrameData:video_frame_bytes length:length frameInfo:frame_info];
    return 0;
}

- (void)createYUVFrameData:(const void *)buffer length:(unsigned long)length frameInfo:(struct gl_frame_type)frameInfo{
    NSUInteger ylenght = length*2/3;
    
    NSData *dataY = [NSData dataWithBytes:buffer length:ylenght];
    NSData *dataU = [NSData dataWithBytes:buffer+ylenght length:ylenght/4];
    NSData *dataV = [NSData dataWithBytes:buffer+ylenght*5/4 length:ylenght/4];
    
    GlVideoFrameYUVModel *fmodel = [[GlVideoFrameYUVModel alloc] init];
    fmodel.width = YUV_Width;
    fmodel.height = YUV_Height;
    fmodel.time = frameInfo.time;
    fmodel.duration = frameInfo.duration;
    
    fmodel.lumaY = dataY;
    fmodel.chrominanceU = dataU;
    fmodel.chromaV = dataV;
    
    [self.glView addFrame:fmodel];
    
}

/**
 视频解码开始
 */
- (void)media_decoder_start {
    
    self.cview.playOrPauseBtn.selected = YES;
    NSString *mp4filePath = [[NSBundle mainBundle] pathForResource:@"output_ss6_t10" ofType:@"mp4"];
    const char *mp4path = [mp4filePath UTF8String];
    
    NSString *videofilePath = [kPathDocument stringByAppendingPathComponent:@"movie_video.yuv"];
    const char *video_yuv_path = [videofilePath UTF8String];
    NSLog(@"解封装后的video_yuv文件路径：%@",videofilePath);
    
    
    NSString *pcmfilePath = [kPathDocument stringByAppendingPathComponent:@"movie_audioPcm.pcm"];
    const char *pcmpath = [pcmfilePath UTF8String];
    NSLog(@"解码后的pcm文件路径：%@",pcmfilePath);
    
    printf("测试地址指针开始前：\nvideo_yuv_filePath:%p\n音频pcm：%p\n原始地址：%p\n",&video_yuv_path,&pcmpath,&mp4path);
    //注册一些通知
    gl_register_funs(get_audio_data_fun, get_video_data_fun,gl_status_chang_notification,gl_get_format_info_fun);
    //开始初始化一些基本
    gl_init_and_open_decoder((__bridge void *)(self), mp4path);
//    gl_test_init_and_open_decoder_save_file((__bridge void *)(self), mp4path, video_yuv_path, pcmpath);
    //开始解码
    gl_start_decoder();
    
    [self.glView startShowFrame];
}

#pragma mark <GlPlayeAudioDelegate>
//当前音频播放到第几帧，也是主时钟
- (void)curPlayModel:(GlAudioFrameModel *)fmodel {
    NSLog(@"通知主时钟：%f",fmodel.time);
    self.glView.mainClockTime = fmodel.time;
    self.glView.mainDuration = fmodel.duration;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cview.value = fmodel.time + fmodel.duration;
    });
    
}

- (void)playAudioEnd {
    
}

#pragma mark <GlControlViewDelegate>
/**
 点击UISlider获取点击点
 
 @param controlView 控制视图
 @param value 当前点击点
 */
-(void)controlView:(GlControlView *)controlView pointSliderLocationWithCurrentValue:(CGFloat)value {
    
}

/**
 拖拽UISlider的knob的时间响应代理方法
 
 @param controlView 控制视图
 @param slider UISlider
 */
-(void)controlView:(GlControlView *)controlView draggedPositionWithSlider:(UISlider *)slider {
    
}

/**
 点击放大按钮的响应事件
 
 @param controlView 控制视图
 @param button 全屏按钮
 */
-(void)controlView:(GlControlView *)controlView withLargeButton:(UIButton *)button {
    
}

-(void)controlView:(GlControlView *)controlView withPlayOrPauseButton:(UIButton *)button {
    if (button.selected) {
        gl_start_decoder();
        [self.audioManager play];
        [self.glView startShowFrame];
    }else {//点击暂停
        gl_pause_decoder();
        [self.audioManager stop];
        [self.glView pauseShowFrame];
    }
    
}

- (void)dealloc {
    gl_exit_decoder();
}
@end
