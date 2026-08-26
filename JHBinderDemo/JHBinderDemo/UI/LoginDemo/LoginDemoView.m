//
//  LoginDemoView.m
//

#import "LoginDemoView.h"

@interface LoginDemoView ()
@property (nonatomic, strong, readwrite) UITextField *accountField;
@property (nonatomic, strong, readwrite) UITextField *passwordField;
@property (nonatomic, strong, readwrite) UIButton    *loginBtn;
@property (nonatomic, strong, readwrite) UILabel     *statusLabel;
@end

@implementation LoginDemoView

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
    CGFloat pad = 32;
    CGFloat w   = W - pad * 2;
    CGFloat h   = 48;
    CGFloat top = 120;

    // 标题
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(pad, top, w, 40)];
    title.text = @"MVVM 登录示例";
    title.font = [UIFont boldSystemFontOfSize:24];
    title.textAlignment = NSTextAlignmentCenter;
    [self addSubview:title];
    top += 56;

    // 账号输入框
    _accountField = [self p_textField:@"账号（最多 20 字）" frame:CGRectMake(pad, top, w, h)];
    _accountField.keyboardType = UIKeyboardTypeEmailAddress;
    [self addSubview:_accountField];
    top += h + 16;

    // 密码输入框
    _passwordField = [self p_textField:@"密码（6~20 字）" frame:CGRectMake(pad, top, w, h)];
    _passwordField.secureTextEntry = YES;
    [self addSubview:_passwordField];
    top += h + 24;

    // 状态提示
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(pad, top, w, 22)];
    _statusLabel.text = @"请输入账号和密码";
    _statusLabel.font = [UIFont systemFontOfSize:13];
    _statusLabel.textColor = UIColor.secondaryLabelColor;
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_statusLabel];
    top += 32;

    // 登录按钮
    _loginBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _loginBtn.frame = CGRectMake(pad, top, w, h);
    [_loginBtn setTitle:@"登录" forState:UIControlStateNormal];
    _loginBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    _loginBtn.backgroundColor = UIColor.systemBlueColor;
    [_loginBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _loginBtn.layer.cornerRadius = 12;
    _loginBtn.enabled = NO;
    _loginBtn.alpha = 0.4f;
    [self addSubview:_loginBtn];
}

- (UITextField *)p_textField:(NSString *)placeholder frame:(CGRect)frame {
    UITextField *tf = [[UITextField alloc] initWithFrame:frame];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.font = [UIFont systemFontOfSize:16];
    return tf;
}

@end
