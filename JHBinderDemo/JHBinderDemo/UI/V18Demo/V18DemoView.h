//
//  V18DemoView.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/28/26.
//
//  v1.8 新特性演示视图（5 组）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface V18DemoView : UIScrollView

// ① format
@property (nonatomic, strong) UISlider *priceSlider;         ///< 0 ~ 999.99
@property (nonatomic, strong) UILabel  *priceLabel;          ///< format(@"¥%.2f")
@property (nonatomic, strong) UIStepper *countStepper;       ///< 0 ~ 99
@property (nonatomic, strong) UILabel  *countLabel;          ///< format(@"共 %@ 件")

// ② notNil
@property (nonatomic, strong) UIButton *notNilNilButton;     ///< 设为 nil
@property (nonatomic, strong) UIButton *notNilNullButton;    ///< 设为 NSNull
@property (nonatomic, strong) UIButton *notNilValueButton;   ///< 设为 "有效值"
@property (nonatomic, strong) UILabel  *notNilResultLabel;   ///< 只有"有效值"才更新

// ③ required
@property (nonatomic, strong) UITextField *requiredField;    ///< 输入内容
@property (nonatomic, strong) UILabel     *requiredLabel;    ///< 非空才更新

// ④ pausable
@property (nonatomic, strong) UIButton    *loginToggleButton; ///< 切换登录状态
@property (nonatomic, strong) UILabel     *loginStateLabel;   ///< 显示当前登录状态
@property (nonatomic, strong) UITextField *pausableField;     ///< 只在已登录时同步
@property (nonatomic, strong) UILabel     *pausableResultLabel;///< 已登录才更新

// ⑤ rebind
@property (nonatomic, strong) UIButton *rebindToAButton;     ///< 切换到 cardA
@property (nonatomic, strong) UIButton *rebindToBButton;     ///< 切换到 cardB
@property (nonatomic, strong) UILabel  *rebindCardLabel;     ///< 显示当前绑定的 cardName
@property (nonatomic, strong) UIButton *rebindUpdateButton;  ///< 修改当前绑定 model 的 cardName

@end

NS_ASSUME_NONNULL_END
