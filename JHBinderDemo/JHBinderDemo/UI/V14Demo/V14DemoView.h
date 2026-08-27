//
//  V14DemoView.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface V14DemoView : UIView

// ① defaultValue
@property (nonatomic, strong, readonly) UITextField *defaultField;
@property (nonatomic, strong, readonly) UILabel     *defaultResultLabel;
@property (nonatomic, strong, readonly) UIButton    *resetButton;       ///< 点击 → 清空模型值 → label 显示默认

// ② skip(N)
@property (nonatomic, strong, readonly) UITextField *skipField;
@property (nonatomic, strong, readonly) UILabel     *skipResultLabel;
@property (nonatomic, strong, readonly) UILabel     *skipHintLabel;     ///< 显示 "还需跳过 N 次"

// ③ take(N)
@property (nonatomic, strong, readonly) UITextField *takeField;
@property (nonatomic, strong, readonly) UILabel     *takeResultLabel;
@property (nonatomic, strong, readonly) UILabel     *takeCountLabel;    ///< 剩余可广播次数

// ④ throttle(t) — 前沿
@property (nonatomic, strong, readonly) UITextField *throttleField;
@property (nonatomic, strong, readonly) UILabel     *throttleResultLabel;
@property (nonatomic, strong, readonly) UILabel     *throttleCountLabel; ///< 实际广播次数

// ⑤ throttleTrailing(t) — 前沿 + 后沿
@property (nonatomic, strong, readonly) UITextField *throttleTrailingField;
@property (nonatomic, strong, readonly) UILabel     *throttleTrailingResultLabel;
@property (nonatomic, strong, readonly) UILabel     *throttleTrailingCountLabel;

// ⑥ throttleTrailingOnly(t) — 后沿
@property (nonatomic, strong, readonly) UITextField *throttleTrailingOnlyField;
@property (nonatomic, strong, readonly) UILabel     *throttleTrailingOnlyResultLabel;
@property (nonatomic, strong, readonly) UILabel     *throttleTrailingOnlyCountLabel;

@end

NS_ASSUME_NONNULL_END
