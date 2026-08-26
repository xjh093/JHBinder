//
//  BasicDemoView.m
//

#import "BasicDemoView.h"

@interface BasicDemoView ()
@property (nonatomic, strong, readwrite) UITextField *textField;
@property (nonatomic, strong, readwrite) UILabel     *syncLabel;
@property (nonatomic, strong, readwrite) UIButton    *setValueBtn;
@end

@implementation BasicDemoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.systemBackgroundColor;
        [self p_setupViews];
    }
    return self;
}

- (void)p_setupViews {
    CGFloat W = UIScreen.mainScreen.bounds.size.width;
    CGFloat pad = 20;
    CGFloat w = W - pad * 2;
    CGFloat h = 44;
    CGFloat top = 100;
    CGFloat gap = 16;

    // 说明文字
    UILabel *tipTextField = [self p_makeTipLabel:@"在下方输入框中输入内容："];
    tipTextField.frame = CGRectMake(pad, top, w, 24);
    [self addSubview:tipTextField];
    top += 28;

    // UITextField
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(pad, top, w, h)];
    _textField.placeholder = @"请输入内容...";
    _textField.borderStyle = UITextBorderStyleRoundedRect;
    _textField.font = [UIFont systemFontOfSize:16];
    [self addSubview:_textField];
    top += h + gap * 2;

    // 说明文字
    UILabel *tipLabel = [self p_makeTipLabel:@"绑定 Label 同步显示（receive 接收方）："];
    tipLabel.frame = CGRectMake(pad, top, w, 24);
    [self addSubview:tipLabel];
    top += 28;

    // 同步 Label
    _syncLabel = [[UILabel alloc] initWithFrame:CGRectMake(pad, top, w, h)];
    _syncLabel.text = @"（等待输入...）";
    _syncLabel.textColor = UIColor.systemBlueColor;
    _syncLabel.font = [UIFont systemFontOfSize:16];
    _syncLabel.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.05f];
    _syncLabel.layer.cornerRadius = 8;
    _syncLabel.layer.masksToBounds = YES;
    _syncLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_syncLabel];
    top += h + gap * 3;

    // 按钮：通过代码修改 Model 属性
    _setValueBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _setValueBtn.frame = CGRectMake(pad, top, w, h);
    [_setValueBtn setTitle:@"代码写入 model.text = \"Hello JHBinder\"" forState:UIControlStateNormal];
    _setValueBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    _setValueBtn.backgroundColor = UIColor.systemBlueColor;
    [_setValueBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _setValueBtn.layer.cornerRadius = 10;
    [self addSubview:_setValueBtn];
}

- (UILabel *)p_makeTipLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:13];
    label.textColor = UIColor.secondaryLabelColor;
    return label;
}

@end
