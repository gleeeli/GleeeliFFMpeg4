//
//  ViewController.m
//  GleeeliFFMpeg4
//
//  Created by 小柠檬 on 2019/6/20.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import "ViewController.h"
#include "decode_audio_4.h"
#import "CommHeader.h"
#import "ResampleAudio.h"
#import "demuxing_decoding.h"
#import "decode_video.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) ResampleAudio *audio;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *muArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.muArray = [[NSMutableArray alloc] init];
    [self.muArray addObject:@"解码音频，mp2转pcm"];
    [self.muArray addObject:@"解码视频，h264解码，每一帧单独存为一个YUV文件"];
    [self.muArray addObject:@"解封装，mp4生成h264，生成YUV，生成PCM"];
    
}

- (void)decode_video {
    NSString *inputFilePath = [[NSBundle mainBundle] pathForResource:@"output" ofType:@"h264"];
    const char *h264FilePath = [inputFilePath UTF8String];
    
    NSLog(@"解封装前的h264文件路径：%@",inputFilePath);
    
    NSString *yuvfilePath = [kPathDocument stringByAppendingPathComponent:@"decode_video.yuv"];
    const char *yuvpath = [yuvfilePath UTF8String];
    NSLog(@"解封装后的video_yuv文件路径：%@",yuvfilePath);
    
    start_main_decode_video(h264FilePath, yuvpath);
}

- (void)decode_audio {
    NSString *pcmfilePath = [kPathDocument stringByAppendingPathComponent:@"audioPcm.pcm"];
    const char *pcmpath = [pcmfilePath UTF8String];
    NSLog(@"解码后的pcm文件路径：%@",pcmfilePath);
    
    //???
//    NSString *mp3filePath = [[NSBundle mainBundle] pathForResource:@"test2" ofType:@"mp3"];
//    const char *mp3path = [mp3filePath UTF8String];
    
    NSString *mp2filePath = [[NSBundle mainBundle] pathForResource:@"test3" ofType:@"mp2"];
    const char *mp2path = [mp2filePath UTF8String];
    
    
    start_main_decode_audio4(pcmpath, mp2path);
    
    //    self.audio = [[ResampleAudio alloc] init];
    //    [self.audio pcmResample:mp3filePath pcmfilePath:pcmfilePath];
}

//解封装
- (void)demuxing_decoding {
    //yuv420p 2852x1700 MPEG-4
//    NSString *avifilePath = [[NSBundle mainBundle] pathForResource:@"output" ofType:@"avi"];
//    const char *avipath = [avifilePath UTF8String];
    
    NSString *mp4filePath = [[NSBundle mainBundle] pathForResource:@"output_ss6_t10" ofType:@"mp4"];
    const char *mp4path = [mp4filePath UTF8String];
    
    NSString *h264filePath = [kPathDocument stringByAppendingPathComponent:@"demuxing_video.h264"];
    const char *h264path = [h264filePath UTF8String];
    NSLog(@"解封装后的h264文件路径：%@",h264filePath);
    
    NSString *videofilePath = [kPathDocument stringByAppendingPathComponent:@"demuxing_video.yuv"];
    const char *videopath = [videofilePath UTF8String];
    NSLog(@"解封装后的video_yuv文件路径：%@",videofilePath);
    
    NSString *audiofilePath = [kPathDocument stringByAppendingPathComponent:@"demuxing_audio"];
    const char *audiopath = [audiofilePath UTF8String];
    NSLog(@"解封装后的audio文件路径：%@",audiofilePath);
    
    start_main_demuxing_decoding(mp4path,h264path, videopath, audiopath);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.muArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    cell.textLabel.text = self.muArray[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = self.muArray[indexPath.row];
    if ([title isEqualToString:@"解码音频，mp2转pcm"])
    {
        [self decode_audio];
    }
    else if ([title isEqualToString:@"解码视频，h264解码，每一帧单独存为一个YUV文件"])
    {
        [self decode_video];
    }
    else if ([title isEqualToString:@"解封装，mp4生成h264，生成YUV，生成PCM"])
    {
        [self demuxing_decoding];
    }
    
    
}
@end
