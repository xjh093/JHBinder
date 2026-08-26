//
//  ConvertDemoView.m
//

#import "ConvertDemoView.h"

@interface ConvertDemoView ()
@property (nonatomic, strong, readwrite) UITextField *rawField;
@property (nonatomic, strong, readwrite) UITextField *upperField;
@property (nonatomic, strong, readwrite) UITextField *trimField;
@property (nonatomic, strong, readwrite) UILabel     *modelLabel;
@property (nonatomic, strong, readwrite) UIButton    *setValueBtn;
@end

@implementation ConvertDemoView

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
    CGFloat top = 120;
    CGFloat gap = 14;

    // 节点 A：原始输入（twoWayUI，无转换）
    [self addSubview:[self p_tip:@"节点 A — twoWayUI（原始值）：" y:top w:w pad:pad]];
    top += 26;
    _rawField = [self p_field:@"在此输入原始内容..." frame:CGRectMake(pad, top, w, h)];
    [self addSubview:_rawField];
    top += h + gap;

    // 节点 B：转大写（twoWayUIMap）
    [self addSubview:[self p_tip:@"节点 B — twoWayUIMap（接收时转大写）：" y:top w:w pad:pad]];
    top += 26;
    _upperField = [self p_field:@"自动显示大写..." frame:CGRectMake(pad, top, w, h)];
    _upperField.textColor = UIColor.systemOrangeColor;
    [self addSubview:_upperField];
    top += h + gap;

    // 节点 C：去首尾空格（twoWayUIMap）
    [self addSubview:[self p_tip:@"节点 C — twoWayUIMap（接收时 trim 首尾空格）：" y:top w:w pad:pad]];
    top += 26;
    _trimField = [self p_field:@"自动去除首尾空格..." frame:CGRectMake(pad, top, w, h)];
    _trimField.textColor = UIColor.systemGreenColor;
    [self addSubview:_trimField];
    top += h + gap;

    // 节点 D：显示 model.text（receive）
    [self addSubview:[self p_tip:@"节点 D — receive（model.text 当前存储值）：" y:top w:w pad:pad]];
    top += 26;
    _modelLabel = [[UILabel alloc] initWithFrame:CGRectMake(pad, top, w, h)];
    _modelLabel.text = @"（等待输入...）";
    _modelLabel.font = [UIFont systemFontOfSize:15];
    _modelLabel.textColor = UIColor.systemPurpleColor;
    _modelLabel.backgroundColor = [UIColor.systemPurpleColor colorWithAlphaComponent:0.06f];
    _modelLabel.layer.cornerRadius = 8;
    _modelLabel.layer.masksToBounds = YES;
    _modelLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_modelLabel];
    top += h + gap + 8;

    // 按钮：代码写入含空格的值
    _setValueBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _setValueBtn.frame = CGRectMake(pad, top, w, h);
    [_setValueBtn setTitle:@"代码写入 \"  hello world  \"（含首尾空格）" forState:UIControlStateNormal];
    _setValueBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    _setValueBtn.backgroundColor = UIColor.systemBlueColor;
    [_setValueBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _setValueBtn.layer.cornerRadius = 10;
    [self addSubview:_setValueBtn];
}

- (UILabel *)p_tip:(NSString *)text y:(CGFloat)y w:(CGFloat)w pad:(CGFloat)pad {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(pad, y, w, 22)];
    l.text = text;
    l.font = [UIFont systemFontOfSize:12];
    l.textColor = UIColor.secondaryLabelColor;
    return l;
}

- (UITextField *)p_field:(NSString *)placeholder frame:(CGRect)frame {
    UITextField *tf = [[UITextField alloc] initWithFrame:frame];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.font = [UIFont systemFontOfSize:16];
    return tf;
}

@end
