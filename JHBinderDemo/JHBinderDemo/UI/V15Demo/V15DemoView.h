//
//  V15DemoView.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface V15DemoView : UIView

// ① transform — 链级值变换（大写）
@property (nonatomic, strong, readonly) UITextField *transformField;
@property (nonatomic, strong, readonly) UILabel     *transformResultLabel; ///< 显示大写后的文本

// ② scan — 累加器（统计历史输入字符总数）
@property (nonatomic, strong, readonly) UITextField *scanField;
@property (nonatomic, strong, readonly) UILabel     *scanResultLabel;      ///< 显示累计字符数
@property (nonatomic, strong, readonly) UILabel     *scanHistoryLabel;     ///< 显示每次广播的字数变化

// ③ withPrevious — 双值打包
@property (nonatomic, strong, readonly) UITextField *withPreviousField;
@property (nonatomic, strong, readonly) UILabel     *withPreviousResultLabel; ///< 显示 "prev → now"

// ④ biMap — 双向映射（NSNumber ↔ NSString）
@property (nonatomic, strong, readonly) UITextField *biMapField;         ///< 输入数字字符串
@property (nonatomic, strong, readonly) UILabel     *biMapValueLabel;    ///< 展示 model.countValue（经 forward 转换）
@property (nonatomic, strong, readonly) UIButton    *biMapIncrButton;    ///< +1
@property (nonatomic, strong, readonly) UIButton    *biMapDecrButton;    ///< -1

@end

NS_ASSUME_NONNULL_END
