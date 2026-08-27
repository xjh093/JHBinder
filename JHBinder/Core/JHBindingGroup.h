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


// MARK: - v1.2 新增配置（链式 DSL 通过 JHBinder 设置）

/// 防抖间隔（秒）：停止触发后延迟广播，连续触发时重置计时器，>0 生效
@property (nonatomic, assign) NSTimeInterval debounceInterval;

/// 延迟广播（秒）：每次触发延迟固定时间后广播，不取消前次，>0 生效
/// 注：debounce 和 delay 同时设置时，debounce 优先
@property (nonatomic, assign) NSTimeInterval delayInterval;

/// 首次广播后自动移除所有节点（解绑），适用于"只关心一次变化"场景
@property (nonatomic, assign) BOOL isOnce;

/// UIControl 相同值不重复广播（KVO 路径已内置此行为）
@property (nonatomic, assign) BOOL isDistinct;

/// 调试标签，非 nil 时每次广播打印日志：[JHBinder:label] nodeID → value
@property (nonatomic, copy, nullable) NSString *debugLabel;

/// 立即用第一个监听节点的当前值广播一次（fire 实现）
- (void)fireFromFirstListenNode;


// MARK: - v1.4 新增配置

/// 默认值：广播值为 nil / NSNull 时替换为此值，防止接收节点出现空白
@property (nonatomic, strong, nullable) id defaultValue;

/// 跳过前 N 次广播（设置后立即生效）
@property (nonatomic, assign) NSUInteger skipCount;

/// 只广播 N 次后自动解绑（0 = 不限次数）；.once() 等价于 takeCount = 1
@property (nonatomic, assign) NSUInteger takeCount;

/// 节流间隔（秒）：配合 throttleMode 使用，>0 生效
@property (nonatomic, assign) NSTimeInterval throttleInterval;

/// 节流模式（v1.4）：默认 JHThrottleModeLead（前沿触发）
/// - JHThrottleModeLead：第一次立即通过，窗口期内后续丢弃
/// - JHThrottleModeLeadTrail：第一次立即通过 + 窗口结束时补发最后值
/// - JHThrottleModeTrail：仅在窗口结束时发出最后一个值
@property (nonatomic, assign) JHThrottleMode throttleMode;

@end

NS_ASSUME_NONNULL_END
