//
//  JHIntervalRelay.h
//  JHBinder
//
//  Created by Haomissyou on 8/27/26.
//
//  interval(t) 的 KVO 定时器源。
//  内部用 dispatch_source 每隔 t 秒递增 tick，JHBinder KVO 监听 tick 触发广播。
//  dealloc 时自动取消定时器，无需手动释放。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JHIntervalRelay : NSObject

/// 每次定时器触发时递增（0, 1, 2, …），KVO-observable
@property (nonatomic, strong, nullable) NSNumber *tick;

/// 启动定时器（只应调用一次）
- (void)startWithInterval:(NSTimeInterval)interval;

/// 手动停止定时器（dealloc 时自动调用）
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
