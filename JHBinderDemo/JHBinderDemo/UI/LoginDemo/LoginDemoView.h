//
//  LoginDemoView.h
//

#import <UIKit/UIKit.h>

@interface LoginDemoView : UIView

@property (nonatomic, strong, readonly) UITextField *accountField;
@property (nonatomic, strong, readonly) UITextField *passwordField;
@property (nonatomic, strong, readonly) UIButton    *loginBtn;
@property (nonatomic, strong, readonly) UILabel     *statusLabel;  ///< 显示校验提示

@end
