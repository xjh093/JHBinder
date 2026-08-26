//
//  JHBindingGroup.h
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//
//  广播组：持有一组绑定节点，作为 KVO Observer，负责值传播
//  特点：
//    1. 用 dispatch_barrier_async 保护 nodeMap 读写（线程安全）
//    2. 用 groupID 集合防多链循环广播
//    3. @try/@catch 保护 removeObserver（防止 crash）
//

#import <UIKit/UIKit.h>
#import "JHBinderDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class JHBindingNode;

@interface JHBindingGroup : NSObject

/// 广播组唯一 ID（UUID）
@property (nonatomic, copy, readonly) NSString *groupID;

/// 当前节点数量
@property (nonatomic, assign, readonly) NSUInteger nodeCount;

- (instancetype)initWithGroupID:(NSString *)groupID;

// MARK: - 节点管理
- (void)addNode:(JHBindingNode *)node;
- (void)removeNodeWithID:(NSString *)nodeID;
- (void)removeAllNodes;

/// 移除某个 target 下所有节点（通过 targetHash 前缀匹配 nodeID）
- (void)removeNodesForTargetHash:(NSString *)targetHash;

/// 查询指定 targetHash+keyPath 是否已在本组
- (BOOL)containsNodeForTargetHash:(NSString *)targetHash keyPath:(NSString *)keyPath;

// MARK: - 过滤器
- (void)setFilterBlock:(nullable JHFilterBlock)filterBlock;

@end

NS_ASSUME_NONNULL_END
