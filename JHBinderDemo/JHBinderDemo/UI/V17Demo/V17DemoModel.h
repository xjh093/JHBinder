//
//  V17DemoModel.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//
//  v1.7 新特性演示模型


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface V17DemoModel : NSObject

// ① interval + takeUntil
/// takeUntil 信号：设为任意非 nil 值时触发 ticker 停止
@property (nonatomic, strong, nullable) NSNumber *stopSignal;

// ② pluck
/// 模拟网络返回的嵌套字典，由 pluck(@"user.name") 提取
@property (nonatomic, strong, nullable) NSDictionary *apiResponse;

// ③ bufferCount(3)
/// 每次按按钮递增，用于触发 bufferCount 广播
@property (nonatomic, strong, nullable) NSNumber *bufferEventValue;

// ④ bufferTime(2s)
/// 快速输入文本，bufferTime 每 2 秒打包所有变化
@property (nonatomic, copy, nullable) NSString *rapidText;

// ⑤ timeout(4s)
/// 用户操作后更新，超过 4 秒不更新则 fallback 触发
@property (nonatomic, copy, nullable) NSString *activeText;

// ⑥ sample(1s)
/// 快速点击按钮递增，sample 每秒只推送一次最新值
@property (nonatomic, strong, nullable) NSNumber *rapidCounter;

// ⑦ combine
@property (nonatomic, copy, nullable) NSString *combineA;
@property (nonatomic, copy, nullable) NSString *combineB;

// ⑧ elementAt(3)
/// 每次点击递增，elementAt(3) 只对第 3 次响应
@property (nonatomic, strong, nullable) NSNumber *tapCount;

@end

NS_ASSUME_NONNULL_END
