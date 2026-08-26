//
//  TextFieldDemoView.m
//

#import "TextFieldDemoView.h"

@interface TextFieldDemoView ()
@property (nonatomic, strong, readwrite) UITextField *textField1;
@property (nonatomic, strong, readwrite) UITextField *textField2;
@property (nonatomic, strong, readwrite) UILabel     *labelNormal;
@property (nonatomic, strong, readwrite) UILabel     *labelUpper;
@property (nonatomic, strong, readwrite) UILabel     *counterLabel;
@end

@implementation TextFieldDemoView

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
    CGFloat h   = 44;
    CGFloat top = 100;

    // TextField 1
    [self addSubview:[self p_tipLabel:@"输入框 A（twoWayUI）：" frame:CGRectMake(pad, top, w, 22)]];
    top += 26;
    _textField1 = [self p_textField:@"在此输入..." frame:CGRectMake(pad, top, w, h)];
    [self addSubview:_textField1];
    top += h + 20;

    // TextField 2
    [self addSubview:[self p_tipLabel:@"输入框 B（twoWayUI，与 A 双向同步）：" frame:CGRectMake(pad, top, w, 22)]];
    top += 26;
    _textField2 = [self p_textField:@"与 A 双向同步..." frame:CGRectMake(pad, top, w, h)];
    [self addSubview:_textField2];
    top += h + 20;

    // 原始值 Label
    [self addSubview:[self p_tipLabel:@"receive — 原始文本：" frame:CGRectMake(pad, top, w, 22)]];
    top += 26;
    _labelNormal = [self p_displayLabel:@"（等待输入...）" frame:CGRectMake(pad, top, w, h) color:UIColor.systemBlueColor];
    [self addSubview:_labelNormal];
    top += h + 20;

    // 大写转换 Label
    [self addSubview:[self p_tipLabel:@"receiveMap — 转大写（convert block）：" frame:CGRectMake(pad, top, w, 22)]];
    top += 26;
    _labelUpper = [self p_displayLabel:@"（等待输入...）" frame:CGRectMake(pad, top, w, h) color:UIColor.systemGreenColor];
    [self addSubview:_labelUpper];
    top += h + 20;

    // 字数计数
    _counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(pad, top, w, 22)];
    _counterLabel.font = [UIFont systemFontOfSize:13];
    _counterLabel.textColor = UIColor.secondaryLabelColor;
    _counterLabel.text = @"filter：超过 20 字自动截断";
    _counterLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:_counterLabel];
}

- (UILabel *)p_tipLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.font = [UIFont systemFontOfSize:13];
    l.textColor = UIColor.secondaryLabelColor;
    return l;
}

- (UITextField *)p_textField:(NSString *)placeholder frame:(CGRect)frame {
    UITextField *tf = [[UITextField alloc] initWithFrame:frame];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.font = [UIFont systemFontOfSize:16];
    return tf;
}

- (UILabel *)p_displayLabel:(NSString *)text frame:(CGRect)frame color:(UIColor *)color {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.textColor = color;
    l.font = [UIFont systemFontOfSize:16];
    l.backgroundColor = [color colorWithAlphaComponent:0.05f];
    l.layer.cornerRadius = 8;
    l.layer.masksToBounds = YES;
    l.textAlignment = NSTextAlignmentCenter;
    return l;
}

@end
