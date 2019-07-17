//
//  GlControlView.m
//  GlVideoPlayer
//
//  Created by gleeeli on 2018/12/11.
//  Copyright © 2018年 gleeeli. All rights reserved.
//

#import "GlControlView.h"

@interface GlControlView()
//当前时间
@property (nonatomic,strong) UILabel *timeLabel;
//总时间
@property (nonatomic,strong) UILabel *totalTimeLabel;
//进度条
@property (nonatomic,strong) UISlider *playSlider;
//缓存进度条
@property (nonatomic,strong) UISlider *bufferSlier;
@end

static NSInteger padding = 8;
@implementation GlControlView
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUI];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    
    return self;
}

//懒加载
-(UILabel *)timeLabel{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc]init];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = [UIColor whiteColor];
    }
    return _timeLabel;
}

-(UILabel *)totalTimeLabel{
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc]init];
        _totalTimeLabel.textAlignment = NSTextAlignmentLeft;
        _totalTimeLabel.font = [UIFont systemFontOfSize:12];
        _totalTimeLabel.textColor = [UIColor whiteColor];
    }
    return _totalTimeLabel;
}

-(UISlider *)playSlider{
    if (!_playSlider) {
        _playSlider = [[UISlider alloc]init];
        [_playSlider setThumbImage:[UIImage imageNamed:@"knob"] forState:UIControlStateNormal];
        _playSlider.continuous = YES;
        self.tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
        [_playSlider addTarget:self action:@selector(handleSliderPosition:) forControlEvents:UIControlEventValueChanged];
        [_playSlider addGestureRecognizer:self.tapGesture];
        _playSlider.maximumTrackTintColor = [UIColor clearColor];
        _playSlider.minimumTrackTintColor = [UIColor whiteColor];
    }
    return _playSlider;
}

-(UIButton *)largeButton{
    if (!_largeButton) {
        _largeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _largeButton.contentMode = UIViewContentModeScaleToFill;
        [_largeButton setImage:[UIImage imageNamed:@"gl_full_screen"] forState:UIControlStateNormal];
        [_largeButton addTarget:self action:@selector(hanleLargeBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _largeButton;
}

-(UISlider *)bufferSlier{
    if (!_bufferSlier) {
        _bufferSlier = [[UISlider alloc]init];
        [_bufferSlier setThumbImage:[UIImage new] forState:UIControlStateNormal];
        _bufferSlier.continuous = YES;
        _bufferSlier.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.2];
        _bufferSlier.minimumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.5];
        _bufferSlier.minimumValue = 0.f;
        _bufferSlier.maximumValue = 1.f;
        _bufferSlier.userInteractionEnabled = NO;
    }
    return _bufferSlier;
}

- (UIButton *)playOrPauseBtn {
    if (_playOrPauseBtn == nil) {
        _playOrPauseBtn = [[UIButton alloc] init];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"gl_play"] forState:UIControlStateNormal];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
        [_playOrPauseBtn addTarget:self action:@selector(hanlePlayOrPauseBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _playOrPauseBtn;
}

-(void)setupUI{
    self.isAutoSetTimeStr = YES;
    self.backgroundColor = [UIColor colorWithRed:2/255.0 green:0 blue:0 alpha:0.5];
    [self addSubview:self.playOrPauseBtn];
    [self addSubview:self.timeLabel];
    [self addSubview:self.bufferSlier];
    [self addSubview:self.playSlider];
    [self addSubview:self.totalTimeLabel];
    [self addSubview:self.largeButton];
    //添加约束
//    [self addConstraintsForSubviews];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)deviceOrientationDidChange{
    //添加约束
//    [self addConstraintsForSubviews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateLayout];
}

- (void)updateLayout {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    CGFloat ppW = 23;
    CGFloat ppY = (height - ppW)*0.5;
    self.playOrPauseBtn.frame = CGRectMake(0, ppY, ppW, ppW);
    
    CGFloat tX = CGRectGetMaxX(self.playOrPauseBtn.frame);
    CGFloat tW = [self getWidthWithText:self.timeLabel.text height:height font:self.timeLabel.font];
    self.timeLabel.frame = CGRectMake(tX, 0, tW, height);
    
    CGFloat lgW = 30;
    CGFloat lgX = width - lgW - padding;
    self.largeButton.frame = CGRectMake(lgX, 0, lgW, height);
    
    CGFloat ttW = [self getWidthWithText:self.totalTimeLabel.text height:height font:self.totalTimeLabel.font];
    CGFloat ttX = lgX - ttW;
    self.totalTimeLabel.frame = CGRectMake(ttX, 0, ttW, height);
    
    CGFloat psX = CGRectGetMaxX(self.timeLabel.frame) + padding;
    CGFloat psW = ttX - padding - psX;
    self.playSlider.frame = CGRectMake(psX, 0, psW, height);
    
    self.bufferSlier.frame = self.playSlider.frame;
}

- (void)hanlePlayOrPauseBtn:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(controlView:withPlayOrPauseButton:)]) {
        [self.delegate controlView:self withPlayOrPauseButton:button];
    }
}

-(void)hanleLargeBtn:(UIButton *)button{
    if ([self.delegate respondsToSelector:@selector(controlView:withLargeButton:)]) {
        [self.delegate controlView:self withLargeButton:button];
    }
}
-(void)handleSliderPosition:(UISlider *)slider{
    if ([self.delegate respondsToSelector:@selector(controlView:draggedPositionWithSlider:)]) {
        [self.delegate controlView:self draggedPositionWithSlider:self.playSlider];
    }
}
-(void)handleTap:(UITapGestureRecognizer *)gesture{
    CGPoint point = [gesture locationInView:self.playSlider];
    CGFloat pointX = point.x;
    CGFloat sliderWidth = self.playSlider.frame.size.width;
    CGFloat currentValue = pointX/sliderWidth * self.playSlider.maximumValue;
    if ([self.delegate respondsToSelector:@selector(controlView:pointSliderLocationWithCurrentValue:)]) {
        [self.delegate controlView:self pointSliderLocationWithCurrentValue:currentValue];
    }
}

//setter 和 getter方法
-(void)setValue:(CGFloat)value{
    if (self.isAutoSetTimeStr) {
        
    }
    self.currentTimeSecond = value;
    self.playSlider.value = value;
}
-(CGFloat)value{
    return self.playSlider.value;
}
-(void)setMinValue:(CGFloat)minValue{
    self.playSlider.minimumValue = minValue;
}
-(CGFloat)minValue{
    return self.playSlider.minimumValue;
}
-(void)setMaxValue:(CGFloat)maxValue{
    if (self.isAutoSetTimeStr) {
        self.totalTimeSecond = maxValue;
    }
    self.playSlider.maximumValue = maxValue;
}
-(CGFloat)maxValue{
    return self.playSlider.maximumValue;
}
-(void)setCurrentTime:(NSString *)currentTime{
    self.timeLabel.text = currentTime;
    [self updateLayout];
}
- (void)setCurrentTimeSecond:(long long)currentTimeSecond {
    _currentTimeSecond = currentTimeSecond;
    NSString *curTime = @"";
    if (currentTimeSecond < 60) {
        curTime = [NSString stringWithFormat:@"00:%02lld",currentTimeSecond];
    }else if(currentTimeSecond >= 60 && currentTimeSecond < 3600) {
        long minute = currentTimeSecond / 60;
        long second = currentTimeSecond % 60;
        curTime = [NSString stringWithFormat:@"%02ld:%02ld",minute,second];
    }else if(currentTimeSecond >= 3600) {
        long hour = currentTimeSecond/3600;
        long minute = (currentTimeSecond%3600) / 60;
        long second = ((currentTimeSecond%3600) % 60) % 60;
        curTime = [NSString stringWithFormat:@"%02ld:%.2ld:%.2ld",hour,minute,second];
    }
    
    self.currentTime = curTime;
}

-(NSString *)currentTime{
    return self.timeLabel.text;
}
-(void)setTotalTime:(NSString *)totalTime{
    self.totalTimeLabel.text = totalTime;
    [self updateLayout];
}
-(void)setTotalTimeSecond:(long long)totalTimeSecond {
    _totalTimeSecond = totalTimeSecond;
    NSString *totalTime = @"";
    if (totalTimeSecond < 60) {
        totalTime = [NSString stringWithFormat:@"00:%lld",totalTimeSecond];
    }else if(totalTimeSecond >= 60 && totalTimeSecond < 3600) {
        long minute = totalTimeSecond / 60;
        long second = totalTimeSecond % 60;
        totalTime = [NSString stringWithFormat:@"%02ld:%02ld",minute,second];
    }else if(totalTimeSecond >= 3600) {
        long hour = totalTimeSecond/3600;
        long minute = (totalTimeSecond%3600) / 60;
        long second = ((totalTimeSecond%3600) % 60) % 60;
        totalTime = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",hour,minute,second];
    }
    
    self.totalTime = totalTime;
}
-(NSString *)totalTime{
    return self.totalTimeLabel.text;
}
-(CGFloat)bufferValue{
    return self.bufferSlier.value;
}
-(void)setBufferValue:(CGFloat)bufferValue{
    self.bufferSlier.value = bufferValue;
}

-(CGFloat)getWidthWithText:(NSString*)text height:(CGFloat)height font:(UIFont *)font{
    if (text == nil || [text isEqualToString:@""]) {
        return 0;
    }
    CGRect rect = [text boundingRectWithSize:CGSizeMake(MAXFLOAT,height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil];
    return rect.size.width;
    
}

@end
