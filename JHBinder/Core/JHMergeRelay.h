//
//  JHMergeRelay.h
//  JHBinder
//
//  Created by Haomissyou on 8/27/26.
//
//  merge 操作的 KVO 中转站。
//  每个源 binder 的 outBlock 把值写入 result；
//  merge binder KVO 监听 result，任一源发射时即触发下游广播。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JHMergeRelay : NSObject

/// 任一源发射时更新此属性，触发 merge binder 的 KVO 广播
@property (nonatomic, strong, nullable) id result;

@end

NS_ASSUME_NONNULL_END
