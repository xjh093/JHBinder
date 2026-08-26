//
//  SliderDemoView.m
//

#import "SliderDemoView.h"

@interface SliderDemoView ()
@property (nonatomic, strong, readwrite) UILabel        *valueLabel;
@property (nonatomic, strong, readwrite) UISlider       *slider;
@property (nonatomic, strong, readwrite) UIProgressView *progressView;
@property (nonatomic, strong, readwrite) UIButton       *randomBtn;
@end

@implementation SliderDemoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.systemBackgroundColor;
        [self p_setupViews];
    }
    return self;
}

- (void)p_setupViews {
    CGFloat W   = UIScreen.mainScreen.bounds.size.width;
    CGFloat pad = 20;
    CGFloat w   = W - pad * 2;
    CGFloat top = 100;

    // 百分比 Label
    _valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(pad, top, w, 60)];
    _valueLabel.text = @"0%";
    _valueLabel.font = [UIFont boldSystemFontOfSize:48];
    _valueLabel.textAlignment = NSTextAlignmentCenter;
    _valueLabel.textColor = UIColor.systemBlueColor;
    [self addSubview:_valueLabel];
    top += 72;

    // UISlider
    [self addSubview:[self p_tipLabel:@"UISlider（twoWayUI）：" frame:CGRectMake(pad, top, w, 22)]];
    top += 26;
    _slider = [[UISlider alloc] initWithFrame:CGRectMake(pad, top, w, 32)];
    _slider.minimumValue = 0;
    _slider.maximumValue = 1;
    _slider.value = 0;
    _slider.tintColor = UIColor.systemBlueColor;
    [self addSubview:_slider];
    top += 48;

    // UIProgressView
    [self addSubview:[self p_tipLabel:@"UIProgressView（receiveMap 同步，range 相同无需转换）：" frame:CGRectMake(pad, top, w, 22)]];
    top += 26;
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.frame = CGRectMake(pad, top, w, 8);
    _progressView.trackTintColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.15f];
    _progressView.progressTintColor = UIColor.systemBlueColor;
    [self addSubview:_progressView];
    top += 40;

    // 按钮
    _randomBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _randomBtn.frame = CGRectMake(pad, top + 20, w, 44);
    [_randomBtn setTitle:@"随机修改 model.sliderValue（代码写入）" forState:UIControlStateNormal];
    _randomBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    _randomBtn.backgroundColor = UIColor.systemBlueColor;
    [_randomBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _randomBtn.layer.cornerRadius = 10;
    [self addSubview:_randomBtn];
}

- (UILabel *)p_tipLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.font = [UIFont systemFontOfSize:13];
    l.textColor = UIColor.secondaryLabelColor;
    return l;
}

@end
