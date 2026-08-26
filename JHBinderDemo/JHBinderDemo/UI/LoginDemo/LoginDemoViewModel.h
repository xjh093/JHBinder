//
//  LoginDemoViewModel.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  演示 MVVM 登录界面的 ViewModel
//

#import <Foundation/Foundation.h>

@interface LoginDemoViewModel : NSObject

@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *password;

/// 计算属性：账号和密码都不为空时返回 YES
@property (nonatomic, assign, readonly) BOOL loginBtnEnabled;

/// 账号格式校验（filter block 中使用）：长度 <= 20
- (BOOL)validateAccount:(NSString *)account;

/// 密码格式校验（filter block 中使用）：长度 6~20
- (BOOL)validatePassword:(NSString *)password;

/// 模拟登录
- (void)login;

@end
