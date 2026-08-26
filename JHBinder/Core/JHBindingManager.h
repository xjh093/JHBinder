//
//  JHBindingManager.h
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//
//  单例管理器：持有所有 JHBindingGroup 的生命周期
//  支持通过 target / groupID 查询和解绑
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class JHBindingGroup;

@interface JHBindingManager : NSObject

+ (instancetype)shared;

// MARK: - Group 生命周期
/// 创建新 Group，生成 UUID 作为 groupID，注册到 manager
- (JHBindingGroup *)createGroup;

/// 通过 groupID 查找 Group
- (nullable JHBindingGroup *)groupWithID:(NSString *)groupID;

/// 从 manager 中移除 Group（Group dealloc 时自动解绑所有节点）
- (void)removeGroupWithID:(NSString *)groupID;

// MARK: - 解绑（面向外部调用）
/// 解绑某个 target 下所有绑定
- (void)unbindTarget:(id)target;

/// 解绑某个 target 的指定 keyPath
- (void)unbindTarget:(id)target keyPath:(NSString *)keyPath;

// MARK: - 查询
- (BOOL)isTarget:(id)target boundForKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
