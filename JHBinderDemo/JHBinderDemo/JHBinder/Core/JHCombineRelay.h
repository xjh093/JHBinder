//
//  JHCombineRelay.h
//  Haomissyou
//
//  Created by Haomissyou on 8/26/26.
//
//  combineLatest 内部中继 Model（v1.3）
//  不对外暴露，不写入公共头文件。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * combineLatest 的内部中继对象。
 *
 * 原理：
 *   - 持有 N 个 slot（对应 N 个 source binder），初始均为 NSNull
 *   - 任意 source 发射新值时，调用 -updateValue:atIndex:
 *   - 所有 slot 均填充后，运行 combineBlock，将结果写入 result（KVO-compliant）
 *   - 外部 combine binder 监听 result 属性，从而驱动链的其余接收节点
 */
@interface JHCombineRelay : NSObject

/// combine 产出值（KVO-compliant），所有 source 至少各发射一次后才会被赋值
@property (nonatomic, strong, nullable) id result;

- (instancetype)initWithCount:(NSUInteger)count
                 combineBlock:(id _Nullable (^)(NSArray *values))combineBlock NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// 某个 source（index）发射了新值，线程安全
- (void)updateValue:(nullable id)value atIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
