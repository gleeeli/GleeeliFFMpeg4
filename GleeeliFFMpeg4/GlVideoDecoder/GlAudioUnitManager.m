//
//  GlAudioUnitManager.m
//  GleeeliFFMpeg4
//
//  Created by 小柠檬 on 2019/7/12.
//  Copyright © 2019 gleeeli. All rights reserved.
//

#import "GlAudioUnitManager.h"
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#import <assert.h>

#define OUTPUT_BUS 0

@implementation GlAudioUnitManager
{
    AudioUnit audioUnit;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.nb_samples = 1;
        self.channel = 1;//1 2
        self.mBitsPerChannel = 16;//8 16 32
        self.queueArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)play {
    [self.queueArray removeAllObjects];
    [self initPlayer];
    AudioOutputUnitStart(audioUnit);
}

- (void)initPlayer {
    
    NSError *error = nil;
    OSStatus status = noErr;
    
    // set audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    AudioComponentDescription audioDesc;
    audioDesc.componentType = kAudioUnitType_Output;
    audioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags = 0;
    audioDesc.componentFlagsMask = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    AudioComponentInstanceNew(inputComponent, &audioUnit);
    
    //audio property
    UInt32 flag = 1;
    if (flag) {
        status = AudioUnitSetProperty(audioUnit,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Output,
                                      OUTPUT_BUS,
                                      &flag,
                                      sizeof(flag));
    }
    if (status) {
        NSLog(@"AudioUnitSetProperty error with status:%d", status);
    }
    
    // format
    AudioStreamBasicDescription outputFormat;
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate       = self.samplerate; // 采样率
    outputFormat.mFormatID         =  kAudioFormatLinearPCM; // PCM格式
    
    if ([self.formatFlags isEqualToString:@"int16"]) {
        outputFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger;
        if (self.isBigEndian) {
            outputFormat.mFormatFlags      = (kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsBigEndian);
        }
    }else if ([self.formatFlags isEqualToString:@"float32"]) {
        outputFormat.mFormatFlags      = kLinearPCMFormatFlagIsFloat;
        if (self.isBigEndian) {
            outputFormat.mFormatFlags      = (kLinearPCMFormatFlagIsFloat | kLinearPCMFormatFlagIsBigEndian);
        }
    }
    
    //就是每个packet的中frame的个数
    outputFormat.mFramesPerPacket  =  self.nb_samples;
    outputFormat.mChannelsPerFrame = self.channel; // 声道数
    //    outputFormat.mBytesPerFrame    = 2; // 每帧只有2个byte 声道*位深*Packet数
    //    outputFormat.mBytesPerPacket   = 2; // 每个Packet只有2个byte
    outputFormat.mBitsPerChannel   = self.mBitsPerChannel;//16; // 每个采样数据的位数
    outputFormat.mReserved = 0;
    
    //方法一 此时outputFormat.mFramesPerPacket必须等于1
    //    outputFormat.mBytesPerPacket = outputFormat.mBytesPerFrame = (outputFormat.mBitsPerChannel/8) * outputFormat.mChannelsPerFrame;
    
    //方法二
    outputFormat.mBytesPerFrame = (outputFormat.mBitsPerChannel/8   * outputFormat.mChannelsPerFrame);
    
    //每个packet中数据的字节数。
    outputFormat.mBytesPerPacket = outputFormat.mBytesPerFrame * outputFormat.mFramesPerPacket;
    
    [self printAudioStreamBasicDescription:outputFormat];
    
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  OUTPUT_BUS,
                                  &outputFormat,
                                  sizeof(outputFormat));
    if (status) {
        NSLog(@"AudioUnitSetProperty eror with status:%d", status);
    }
    
    
    // callback
    AURenderCallbackStruct playCallback;
    playCallback.inputProc = PlayCallback;
    playCallback.inputProcRefCon = (__bridge void *)self;
    AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         OUTPUT_BUS,
                         &playCallback,
                         sizeof(playCallback));
    
    
    OSStatus result = AudioUnitInitialize(audioUnit);
    NSLog(@"result %d", result);
    [self setAGCOn:YES];
}

-(void)setAGCOn: (BOOL)isOn{
    UInt32 agc;
    if(isOn){
        agc = 1;
    }else{
        agc = 0;
    }
    
    OSStatus status = AudioUnitSetProperty(audioUnit,
                                           kAUVoiceIOProperty_VoiceProcessingEnableAGC,
                                           kAudioUnitScope_Global,
                                           0,
                                           &agc,
                                           sizeof(agc));
    NSLog(@"status:%d",status);
    //    CheckError(status, "set ACG");
}


static OSStatus PlayCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData) {
    GlAudioUnitManager *player = (__bridge GlAudioUnitManager *)inRefCon;
    

    if ([player.queueArray count] > 0) {
        NSData *data = [player.queueArray firstObject];
        
        //获取内存地址
        UInt32 *frameBuffer = ioData->mBuffers[0].mData;
        //拷贝到frameBuffer
        memcpy(frameBuffer, data.bytes, data.length);
        ioData->mBuffers[0].mDataByteSize = (unsigned int)data.length;
        
        [player.queueArray removeObjectAtIndex:0];
    }
    
//    if (ioData->mBuffers[0].mDataByteSize <= 0) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [player stop];
//        });
//    }
    return noErr;
}


- (void)stop {
    AudioOutputUnitStop(audioUnit);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(playEnd)]) {
        [self.delegate playEnd];
    }

}

- (void)dealloc {
    AudioOutputUnitStop(audioUnit);
    AudioUnitUninitialize(audioUnit);
    AudioComponentInstanceDispose(audioUnit);
    [self.queueArray removeAllObjects];
}


- (void)printAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd {
    char formatID[5];
    UInt32 mFormatID = CFSwapInt32HostToBig(asbd.mFormatID);
    bcopy (&mFormatID, formatID, 4);
    formatID[4] = '\0';
    printf("Sample Rate:         %10.0f\n",  asbd.mSampleRate);
    printf("Format ID:           %10s\n",    formatID);
    printf("Format Flags:        %10X\n",    (unsigned int)asbd.mFormatFlags);
    printf("Bytes per Packet:    %10d\n",    (unsigned int)asbd.mBytesPerPacket);
    printf("Frames per Packet:   %10d\n",    (unsigned int)asbd.mFramesPerPacket);
    printf("Bytes per Frame:     %10d\n",    (unsigned int)asbd.mBytesPerFrame);
    printf("Channels per Frame:  %10d\n",    (unsigned int)asbd.mChannelsPerFrame);
    printf("Bits per Channel:    %10d\n",    (unsigned int)asbd.mBitsPerChannel);
    printf("\n");
}
@end
