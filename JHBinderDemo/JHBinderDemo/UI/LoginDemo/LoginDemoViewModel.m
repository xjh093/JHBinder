//
//  LoginDemoViewModel.m
//

#import "LoginDemoViewModel.h"

@implementation LoginDemoViewModel

- (BOOL)loginBtnEnabled {
    return self.account.length > 0 && self.password.length >= 6;
}

- (BOOL)validateAccount:(NSString *)account {
    return account.length <= 20;
}

- (BOOL)validatePassword:(NSString *)password {
    return password.length <= 20;
}

- (void)login {
    NSLog(@"[LoginDemo] 模拟登录 — account: %@  password: %@", self.account, self.password);
    // 实际项目中调用网络请求
}

@end
