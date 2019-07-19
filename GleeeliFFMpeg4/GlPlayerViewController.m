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
#define GlTransitionTime 0.2 //全屏时动画时间
#define GlControlHeight 40 //底部控件的高度

@interface GlPlayerViewController ()<GlPlayeAudioDelegate,GlControlViewDelegate>
@property (nonatomic, strong) GlAudioUnitManager *audioManager;
@property (nonatomic, strong) GlVideoFrameView *videoView;
@property (nonatomic, strong) GlControlView *controlView;
@property (nonatomic, assign) BOOL isDrageing;//是否正在拖拽
//是否全屏
@property (nonatomic,assign,readonly) BOOL isFullScreen;
@property (nonatomic, assign) CGRect defaultFrame;
@end

@implementation GlPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initAudio];
    [self initVideo];
    [self media_decoder_start];
    
    [self addNotificationCenter];
}

//MARK:添加消息中心
-(void)addNotificationCenter{

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)initAudio {
    
    /*音频处理*/
    self.audioManager = [[GlAudioUnitManager alloc] init];
    self.audioManager.delegate = self;

}

/**
 初始化视频显示
 */
- (void)initVideo {
    NSUInteger widht = YUV_Width;
    NSUInteger height = YUV_Height;
    self.isDrageing = NO;
    
    CGFloat glheight = SCREEN_WIDTH / widht * height;
    
    self.videoView = [[GlVideoFrameView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, glheight)];
    [self.view addSubview:self.videoView];
    self.defaultFrame = self.videoView.frame;
    
    //测试直接显示用的文件： decode_video720x480YUV420P
//    NSString *inputFilePath = [[NSBundle mainBundle] pathForResource:@"176x144_yuv420p" ofType:@"yuv"];
//    const char *yuvFilePath = [inputFilePath UTF8String];
//    unsigned char *buffer = readYUV(yuvFilePath);
    
    CGRect crect = [self getControlFrameWithVideoFrame:self.videoView.frame];
    GlControlView *cview = [[GlControlView alloc] initWithFrame:crect];
    self.controlView = cview;
    cview.delegate = self;
    cview.value = 0;
    cview.minValue = 0.f;
    cview.currentTime = @"00:00";
    cview.totalTime = @"00:00";
//    self.controlView.totalTime = [self convertTime:second];
//    self.controlView.minValue = 0;
//    self.controlView.maxValue = second;
    [self.videoView addSubview:cview];
}

- (CGRect)getControlFrameWithVideoFrame:(CGRect)vFrame {
    
    CGFloat cvH = GlControlHeight;
    CGFloat cvY = vFrame.size.height - cvH;
    CGRect rect = CGRectMake(0, cvY, vFrame.size.width, cvH);
    return rect;
}

#pragma mark 解码通知
//得到时长等信息
void gl_get_format_info_fun(void *inRefCon,struct gl_format_type info) {
    GlPlayerViewController *vc = (__bridge GlPlayerViewController *)inRefCon;
    
    vc.audioManager.samplerate = info.sample_rate;
    vc.audioManager.channel = info.channels;
    vc.audioManager.mBitsPerChannel = info.mBitsPerChannel;
    vc.audioManager.formatFlags = [NSString stringWithCString:info.sample_fmt_str encoding:NSUTF8StringEncoding];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        vc.controlView.maxValue = info.duration;
        
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
    [vc createFrameModelWithData:video_frame_bytes length:length frameInfo:frame_info];
    return 0;
}

/**
 将一帧二进制数据封装到模型中
 */
- (void)createFrameModelWithData:(const void *)buffer length:(unsigned long)length frameInfo:(struct gl_frame_type)frameInfo {
    switch (frameInfo.format) {
        case 0://yuv数据
            {
                [self createYUVFrameData:buffer length:length frameInfo:frameInfo];
            }
            break;
        case 2://rgb数据
        {
            [self createYUVFrameData:buffer length:length frameInfo:frameInfo];
        }
            break;
        default:{
            printf("error:un recognize vider frame format:%d",frameInfo.format);
        }
            break;
    }
}

//创建一帧yuv模型
- (void)createYUVFrameData:(const void *)buffer length:(unsigned long)length frameInfo:(struct gl_frame_type)frameInfo{
    NSUInteger ylenght = length*2/3;
    
    NSData *dataY = [NSData dataWithBytes:buffer length:ylenght];
    NSData *dataU = [NSData dataWithBytes:buffer+ylenght length:ylenght/4];
    NSData *dataV = [NSData dataWithBytes:buffer+ylenght*5/4 length:ylenght/4];
    
    GlVideoFrameYUVModel *fmodel = [[GlVideoFrameYUVModel alloc] init];
    fmodel.width = frameInfo.width;
    fmodel.height = frameInfo.height;
    fmodel.time = frameInfo.time;
    fmodel.duration = frameInfo.duration;
    
    fmodel.lumaY = dataY;
    fmodel.chrominanceU = dataU;
    fmodel.chromaV = dataV;
    
    [self.videoView addFrame:fmodel];
    
}

//创建一帧rgb模型
- (void)createRGBFrameData:(const void *)buffer length:(unsigned long)length frameInfo:(struct gl_frame_type)frameInfo{
    
    GlVideoFrameRGBModel *fmodel = [[GlVideoFrameRGBModel alloc] init];
    fmodel.width = frameInfo.width;
    fmodel.height = frameInfo.height;
    fmodel.time = frameInfo.time;
    fmodel.duration = frameInfo.duration;
    fmodel.rgbData = [NSData dataWithBytes:buffer length:length];
    
    [self.videoView addFrame:fmodel];
    
}

/**
 视频解码开始
 */
- (void)media_decoder_start {
    
    self.controlView.playOrPauseBtn.selected = YES;
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
    
    [self.videoView startShowFrame];
    [self.audioManager play];
}

#pragma mark <GlPlayeAudioDelegate>
//当前音频播放到第几帧，也是主时钟
- (void)curPlayModel:(GlAudioFrameModel *)fmodel {
    NSLog(@"通知主时钟：%f",fmodel.time);
    self.videoView.mainClockTime = fmodel.time;
    self.videoView.mainDuration = fmodel.duration;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isDrageing) {//未拖拽的时候才更新进度
            self.controlView.value = fmodel.time + fmodel.duration;
        }
    });
    
}

- (void)playAudioEnd {
    
}

#pragma mark <GlControlViewDelegate>
-(void)controlView:(GlControlView *)controlView draggedStartWithSlider:(UISlider *)slider {
    NSLog(@"****拖动开始");
    self.isDrageing = YES;
}

-(void)controlView:(GlControlView *)controlView draggedEndWithSlider:(UISlider *)slider {
    NSLog(@"****拖动结束");
    self.isDrageing = NO;
    [self seekToSeconds:slider.value];
}

- (void)seekToSeconds:(double)secondes {
    [self.audioManager clearCache];
    [self.videoView clearCache];
    gl_decoder_seek(secondes);
}

/**
 点击放大按钮的响应事件
 
 @param controlView 控制视图
 @param button 全屏按钮
 */
-(void)controlView:(GlControlView *)controlView withLargeButton:(UIButton *)button {
    if (SCREEN_WIDTH<SCREEN_HEIGHT) {
        [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
    }else{
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
    }
}

-(void)controlView:(GlControlView *)controlView withPlayOrPauseButton:(UIButton *)button {
    if (button.selected) {
        gl_start_decoder();
        [self.audioManager play];
        [self.videoView startShowFrame];
    }else {//点击暂停
        gl_pause_decoder();
        [self.audioManager stop];
        [self.videoView pauseShowFrame];
    }
    
}

#pragma mark 横屏通知
//旋转方向
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector             = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val                  = orientation;

        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
    
    //方法二配合shouldAutorotate返回NO,
    //[[UIApplication sharedApplication] setStatusBarOrientation:orientation];
}

-(void)deviceOrientationDidChange:(NSNotification *)notification{
    UIInterfaceOrientation _interfaceOrientation=[[UIApplication sharedApplication]statusBarOrientation];
    switch (_interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            _isFullScreen = YES;
            CGRect videoRect = [UIApplication sharedApplication].keyWindow.bounds;
            CGRect controlFrame = [self getControlFrameWithVideoFrame:videoRect];

            NSLog(@"横屏frame：%@",NSStringFromCGRect([UIApplication sharedApplication].keyWindow.bounds));
            //删除UIView animate可以去除横竖屏切换过渡动画
            [UIView animateWithDuration:GlTransitionTime delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0. options:UIViewAnimationOptionTransitionCurlUp animations:^{
                self.controlView.frame = controlFrame;
                self.videoView.frame = videoRect;
            } completion:nil];
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
        {
            _isFullScreen = NO;
            [self.view addSubview:self.videoView];
            
            CGRect controlFrame = [self getControlFrameWithVideoFrame:self.defaultFrame];
            //删除UIView animate可以去除横竖屏切换过渡动画
            [UIView animateKeyframesWithDuration:GlTransitionTime delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
                self.controlView.frame = controlFrame;
                self.videoView.frame = self.defaultFrame;
            } completion:nil];
        }
            break;
        case UIInterfaceOrientationUnknown:
            NSLog(@"UIInterfaceOrientationUnknown");
            break;
    }
}

//- (BOOL)shouldAutorotate {
//    return NO;
//}

- (void)dealloc {
    gl_exit_decoder();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
