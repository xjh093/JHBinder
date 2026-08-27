//
//  V17DemoView.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//
//  v1.7 新特性演示视图
//  共 8 组功能展示（每组含标题标签、交互控件、结果标签）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface V17DemoView : UIScrollView

// ① interval + takeUntil
@property (nonatomic, strong, readonly) UILabel  *tickerLabel;      ///< 显示 tick 计数
@property (nonatomic, strong, readonly) UIButton *stopButton;       ///< 点击停止 interval

// ② pluck
@property (nonatomic, strong, readonly) UIButton *pluckRequestButton;  ///< 触发模拟 API 返回
@property (nonatomic, strong, readonly) UILabel  *pluckResultLabel;    ///< 显示 pluck 提取的值

// ③ bufferCount(3)
@property (nonatomic, strong, readonly) UIButton *bufferCountButton;   ///< 每次入队一个值
@property (nonatomic, strong, readonly) UILabel  *bufferCountLabel;    ///< 满 3 个时显示 batch
@property (nonatomic, strong, readonly) UILabel  *bufferCountHintLabel;///< 显示当前已入队数

// ④ bufferTime(2s)
@property (nonatomic, strong, readonly) UITextField *bufferTimeField;  ///< 快速输入
@property (nonatomic, strong, readonly) UILabel     *bufferTimeLabel;  ///< 每 2s 显示 batch

// ⑤ timeout(4s)
@property (nonatomic, strong, readonly) UIButton *timeoutResetButton;  ///< 点击重置超时计时
@property (nonatomic, strong, readonly) UILabel  *timeoutStatusLabel;  ///< 显示状态或超时

// ⑥ sample(1s)
@property (nonatomic, strong, readonly) UIButton *rapidButton;         ///< 快速点击递增
@property (nonatomic, strong, readonly) UILabel  *sampleLabel;         ///< 每秒采样一次显示
@property (nonatomic, strong, readonly) UILabel  *sampleRawLabel;      ///< 显示原始频率

// ⑦ combine
@property (nonatomic, strong, readonly) UITextField *combineFieldA;    ///< 输入 A
@property (nonatomic, strong, readonly) UITextField *combineFieldB;    ///< 输入 B
@property (nonatomic, strong, readonly) UILabel     *combineResultLabel;///< A + B 结果

// ⑧ elementAt(3)
@property (nonatomic, strong, readonly) UIButton *elementAtButton;     ///< 可多次点击
@property (nonatomic, strong, readonly) UILabel  *elementAtLabel;      ///< 只有第 3 次响应

@end

NS_ASSUME_NONNULL_END
