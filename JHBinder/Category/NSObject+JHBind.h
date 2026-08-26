//
//  NSObject+JHBind.h
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//

#import <Foundation/Foundation.h>
#import "JHBinderDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (JHBind)

/// 对象唯一标识（基于 hash，用于在 map 中作 key）
@property (nonatomic, copy, readonly) NSString *jh_hash;

/// 当前是否正处于被更新状态（用于防止链内循环 A→B→A 循环广播）
@property (nonatomic, assign) BOOL jh_isUpdating;

@end

NS_ASSUME_NONNULL_END
