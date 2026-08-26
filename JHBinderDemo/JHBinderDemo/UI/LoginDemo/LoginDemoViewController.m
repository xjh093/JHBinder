//
//  LoginDemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  演示 MVVM 登录界面：
//    - listenUI：textField 单向监听（只广播，不接收）
//    - receive：viewModel 接收账号/密码
//    - filter：校验格式，不合规则丢弃
//    - observe：任一字段变化时重新计算并更新 loginBtn.enabled 和 statusLabel
//

#import "LoginDemoViewController.h"
#import "LoginDemoView.h"
#import "LoginDemoViewModel.h"
#import "JHBinderKit.h"

@interface LoginDemoViewController ()

@property (nonatomic, strong) LoginDemoView      *loginView;
@property (nonatomic, strong) LoginDemoViewModel *viewModel;
@property (nonatomic, strong) NSMutableArray     *bindings;

@end

@implementation LoginDemoViewController

- (void)loadView {
    self.view = [[LoginDemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginView = (LoginDemoView *)self.view;
    self.viewModel = [[LoginDemoViewModel alloc] init];
    self.bindings  = [NSMutableArray array];
    [self p_bindData];
    [self p_setupActions];
}

- (void)p_bindData {
    __weak __typeof(self) weak = self;

    // 账号绑定链：
    //   listenUI → accountField 变化广播
    //   receive  → viewModel.account 接收更新
    //   filter   → 格式校验（超长截断）
    //   observe  → 更新按钮状态 + 提示
    JHBinder
        .listenUI(self.loginView.accountField, @"text", UIControlEventEditingChanged)
        .receive(self.viewModel, @"account")
        .filter(^BOOL(id __unused old, id new) {
            return [weak.viewModel validateAccount:(NSString *)new];
        })
        .observe(@"login.account.changed", ^(id value) {
            // 直接使用广播的新值，不读 viewModel（avoid 时序问题）
            [weak p_updateLoginStatusWithLatestAccount:(NSString *)value
                                      latestPassword:weak.viewModel.password];
        })
        .store(self.bindings);

    // 密码绑定链：
    //   listenUI → passwordField 变化广播
    //   receive  → viewModel.password 接收更新
    //   filter   → 格式校验
    //   observe  → 更新按钮状态 + 提示
    JHBinder
        .listenUI(self.loginView.passwordField, @"text", UIControlEventEditingChanged)
        .receive(self.viewModel, @"password")
        .filter(^BOOL(id __unused old, id new) {
            return [weak.viewModel validatePassword:(NSString *)new];
        })
        .observe(@"login.password.changed", ^(id value) {
            // 直接使用广播的新值，不读 viewModel（avoid 时序问题）
            [weak p_updateLoginStatusWithLatestAccount:weak.viewModel.account
                                      latestPassword:(NSString *)value];
        })
        .store(self.bindings);
}

- (void)p_setupActions {
    [self.loginView.loginBtn addTarget:self
                                action:@selector(p_onLoginTapped)
                      forControlEvents:UIControlEventTouchUpInside];
}

// MARK: - 状态更新

- (void)p_updateLoginStatusWithLatestAccount:(NSString *)account
                             latestPassword:(NSString *)password {
    account  = account  ?: @"";
    password = password ?: @"";

    BOOL enabled = account.length > 0 && password.length >= 6;
    self.loginView.loginBtn.enabled = enabled;
    self.loginView.loginBtn.alpha   = enabled ? 1.0f : 0.4f;

    if (account.length == 0) {
        self.loginView.statusLabel.text = @"请输入账号";
    } else if (password.length == 0) {
        self.loginView.statusLabel.text = @"请输入密码";
    } else if (password.length < 6) {
        self.loginView.statusLabel.text = [NSString stringWithFormat:@"密码至少 6 位，当前 %lu 位",
                                           (unsigned long)password.length];
    } else {
        self.loginView.statusLabel.text = @"✓ 可以登录";
        self.loginView.statusLabel.textColor = UIColor.systemGreenColor;
        return;
    }
    self.loginView.statusLabel.textColor = UIColor.secondaryLabelColor;
}

- (void)p_onLoginTapped {
    [self.view endEditing:YES];
    [self.viewModel login];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"登录成功（模拟）"
                                                                   message:[NSString stringWithFormat:@"账号：%@", self.viewModel.account]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
