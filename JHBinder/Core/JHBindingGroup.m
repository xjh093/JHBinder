//
//  JHBindingGroup.m
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//

#import "JHBindingGroup.h"
#import "JHBindingNode.h"
#import "NSObject+JHBind.h"
#import <CoreFoundation/CoreFoundation.h>

/// 全局正在广播中的 groupID 集合，用于防跨链循环广播（链1→链2→链1）
/// 支持多链嵌套场景
static NSMutableSet<NSString *> *sBroadcastingGroupIDs;

@interface JHBindingGroup ()

@property (nonatomic, copy, readwrite) NSString *groupID;
/// nodeID → JHBindingNode，用于 O(1) 查找
@property (nonatomic, strong) NSMutableDictionary<NSString *, JHBindingNode *> *nodeMap;
/// 按插入顺序存储 nodeID，保证广播时 receive 节点先于 observe block 节点执行
@property (nonatomic, strong) NSMutableArray<NSString *> *nodeOrder;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, copy, nullable) JHFilterBlock filterBlock;
/// debounce 待执行 block（主线程操作，无需额外锁）
@property (nonatomic, strong, nullable) dispatch_block_t pendingDebounceBlock;

@end

// MARK: - v1.4 私有状态（主线程读写，无需额外锁）
@interface JHBindingGroup () {
    NSUInteger       _skipRemaining;          ///< skip 剩余次数
    NSUInteger       _takeRemaining;          ///< take 剩余次数
    CFAbsoluteTime   _throttleLastFireTime;   ///< throttle 上次广播时间戳
    // 后沿节流状态
    id               _throttlePendingValue;   ///< 窗口期内最新被压制的值
    __weak JHBindingNode *_throttlePendingNode; ///< 对应节点（weak，防止循环引用）
    NSUInteger       _throttleTrailingToken;  ///< 令牌，每次新窗口递增，使过期定时器失效
    BOOL             _throttleWindowActive;   ///< 后沿模式下窗口是否正在运行    // v1.5 状态
    id               _scanAccumulated;        ///< scan 累加器当前値
    id               _previousBroadcastValue; ///< withPrevious 上次广播値
}
@end

@implementation JHBindingGroup

// MARK: - 初始化

+ (void)initialize {
    if (self == [JHBindingGroup class]) {
        sBroadcastingGroupIDs = [NSMutableSet set];
    }
}

- (instancetype)initWithGroupID:(NSString *)groupID {
    self = [super init];
    if (self) {
        _groupID = [groupID copy];
        _nodeMap = [NSMutableDictionary dictionary];
        _nodeOrder = [NSMutableArray array];
        NSString *queueLabel = [NSString stringWithFormat:@"com.jhbinder.group.%@", groupID];
        _queue = dispatch_queue_create(queueLabel.UTF8String, DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)dealloc {
    // 所有 KVO / Target-Action 解绑
    // dealloc 中不需要加锁，此时对象已无其他引用
    for (JHBindingNode *node in _nodeMap.allValues) {
        [self p_stopObservingNode:node];
    }
    [_nodeMap removeAllObjects];
}

// MARK: - nodeCount

- (NSUInteger)nodeCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.queue, ^{
        count = self->_nodeMap.count;
    });
    return count;
}

// MARK: - 节点管理

- (void)addNode:(JHBindingNode *)node {
    dispatch_barrier_async(self.queue, ^{
        self->_nodeMap[node.nodeID] = node;
        [self->_nodeOrder addObject:node.nodeID]; // 维护插入顺序
    });
    [self p_startObservingNode:node];
}

- (void)removeNodeWithID:(NSString *)nodeID {
    __block JHBindingNode *node = nil;
    // barrier_sync：等待写操作完成，并拿到 node 强引用后再解绑
    dispatch_barrier_sync(self.queue, ^{
        node = self->_nodeMap[nodeID];
        [self->_nodeMap removeObjectForKey:nodeID];
        [self->_nodeOrder removeObject:nodeID];
    });
    if (node) {
        [self p_stopObservingNode:node];
    }
}

- (void)removeAllNodes {
    __block NSDictionary *snapshot = nil;
    dispatch_barrier_sync(self.queue, ^{
        snapshot = [self->_nodeMap copy];
        [self->_nodeMap removeAllObjects];
        [self->_nodeOrder removeAllObjects];
    });
    for (JHBindingNode *node in snapshot.allValues) {
        [self p_stopObservingNode:node];
    }
}

- (void)removeNodesForTargetHash:(NSString *)targetHash {
    __block NSArray<JHBindingNode *> *removedNodes = nil;
    dispatch_barrier_sync(self.queue, ^{
        NSMutableArray *nodes = [NSMutableArray array];
        NSMutableArray *ids = [NSMutableArray array];
        for (NSString *nodeID in self->_nodeMap.allKeys) {
            if ([nodeID hasPrefix:targetHash]) {
                [nodes addObject:self->_nodeMap[nodeID]];
                [ids addObject:nodeID];
            }
        }
        removedNodes = nodes.copy;
        [self->_nodeMap removeObjectsForKeys:ids];
        [self->_nodeOrder removeObjectsInArray:ids];
    });
    // 在锁外停止 KVO / Target-Action，避免死锁
    for (JHBindingNode *node in removedNodes) {
        [self p_stopObservingNode:node];
    }
}

- (BOOL)containsNodeForTargetHash:(NSString *)targetHash keyPath:(NSString *)keyPath {
    NSString *nodeID = [NSString stringWithFormat:@"%@_%@", targetHash, keyPath];
    __block BOOL result = NO;
    dispatch_sync(self.queue, ^{
        result = (self->_nodeMap[nodeID] != nil);
    });
    return result;
}

- (void)setFilterBlock:(nullable JHFilterBlock)filterBlock {
    _filterBlock = [filterBlock copy];
}

// MARK: - v1.4 自定义 setter（初始化剩余计数器）

- (void)setSkipCount:(NSUInteger)skipCount {
    _skipCount = skipCount;
    _skipRemaining = skipCount;
}

- (void)setTakeCount:(NSUInteger)takeCount {
    _takeCount = takeCount;
    _takeRemaining = takeCount;
}

- (void)setScanInitialValue:(id)scanInitialValue {
    _scanInitialValue = scanInitialValue;
    _scanAccumulated = scanInitialValue; // 设置时同步初始化累加器
}

// MARK: - 私有：开始/停止观察

- (void)p_startObservingNode:(JHBindingNode *)node {
    if (!(node.direction & JHBindDirectionListen)) return;
    id target = node.target;
    if (!target) return;

    if (node.isUIControl) {
        // UIKit 要求必须在主线程操作
        void (^block)(void) = ^{
            [(UIControl *)target addTarget:self
                                    action:@selector(p_onUIControlEvent:)
                          forControlEvents:node.controlEvent];
        };
        [NSThread isMainThread] ? block() : dispatch_sync(dispatch_get_main_queue(), block);
    } else {
        [target addObserver:self
                 forKeyPath:node.keyPath
                    options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    context:(__bridge void *)(node)];
    }
}

- (void)p_stopObservingNode:(JHBindingNode *)node {
    if (!(node.direction & JHBindDirectionListen)) return;
    id target = node.target;
    if (!target) return;

    if (node.isUIControl) {
        // UIKit 要求必须在主线程操作
        void (^block)(void) = ^{
            [(UIControl *)target removeTarget:self
                                       action:@selector(p_onUIControlEvent:)
                             forControlEvents:node.controlEvent];
        };
        [NSThread isMainThread] ? block() : dispatch_sync(dispatch_get_main_queue(), block);
    } else {
        @try {
            [target removeObserver:self
                        forKeyPath:node.keyPath
                           context:(__bridge void *)(node)];
        } @catch (NSException *__unused e) {
            // 已经解绑或从未绑定，忽略
        }
    }
}

// MARK: - KVO 回调

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    // 节点正处于被更新状态（由本组广播触发），跳过防循环
    if (((NSObject *)object).jh_isUpdating) return;

    JHBindingNode *sourceNode = (__bridge JHBindingNode *)(context);

    id oldValue = change[NSKeyValueChangeOldKey];
    id newValue = change[NSKeyValueChangeNewKey];

    // 值未变化，跳过
    if (oldValue && newValue && [oldValue isEqual:newValue]) return;

    // 过滤器拦截
    if (self.filterBlock && !self.filterBlock(oldValue, newValue)) return;

    [self p_scheduleBroadcastFromNode:sourceNode newValue:newValue];
}

// MARK: - UIControl Target-Action 回调

- (void)p_onUIControlEvent:(UIControl *)sender {
    NSString *senderHash = [(NSObject *)sender jh_hash];

    __block JHBindingNode *sourceNode = nil;
    dispatch_sync(self.queue, ^{
        for (JHBindingNode *node in self->_nodeMap.allValues) {
            if (node.isUIControl && [node.targetHash isEqualToString:senderHash]) {
                sourceNode = node;
                break;
            }
        }
    });
    if (!sourceNode) return;

    id newValue = [sender valueForKeyPath:sourceNode.keyPath];

    // distinct：相同值不重复广播（UIControl 路径；KVO 路径已在 observeValueForKeyPath: 内置）
    if (self.isDistinct) {
        if (sourceNode.lastBroadcastValue && [sourceNode.lastBroadcastValue isEqual:newValue]) return;
        sourceNode.lastBroadcastValue = newValue;
    }

    if (self.filterBlock && !self.filterBlock(nil, newValue)) return;

    [self p_scheduleBroadcastFromNode:sourceNode newValue:newValue];
}

// MARK: - 广播调度（throttle / debounce / delay / 直通）

- (void)p_scheduleBroadcastFromNode:(JHBindingNode *)sourceNode newValue:(id)newValue {
    if (self.throttleInterval > 0) {
        void (^onMain)(void) = ^{
            switch (self.throttleMode) {

                case JHThrottleModeLead: {
                    // 前沿：窗口内第一次立即通过，后续丢弃
                    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
                    if (now - self->_throttleLastFireTime < self.throttleInterval) return;
                    self->_throttleLastFireTime = now;
                    [self p_scheduleAfterThrottle:sourceNode newValue:newValue];
                    break;
                }

                case JHThrottleModeLeadTrail: {
                    // 前沿 + 后沿：第一次立即通过；窗口内更新待发值；窗口结束时补发最后一个值
                    if (!self->_throttleWindowActive) {
                        self->_throttleWindowActive = YES;
                        NSUInteger token = ++self->_throttleTrailingToken;
                        self->_throttlePendingValue = nil;
                        self->_throttlePendingNode = nil;
                        [self p_scheduleAfterThrottle:sourceNode newValue:newValue]; // leading
                        [self p_scheduleTrailingWithToken:token];
                    } else {
                        // 窗口期内更新待发值
                        self->_throttlePendingValue = newValue;
                        self->_throttlePendingNode = sourceNode;
                    }
                    break;
                }

                case JHThrottleModeTrail: {
                    // 后沿：窗口开始计时，结束时只发最后一个值
                    if (!self->_throttleWindowActive) {
                        self->_throttleWindowActive = YES;
                        NSUInteger token = ++self->_throttleTrailingToken;
                        self->_throttlePendingValue = newValue;
                        self->_throttlePendingNode = sourceNode;
                        [self p_scheduleTrailingWithToken:token];
                    } else {
                        self->_throttlePendingValue = newValue;
                        self->_throttlePendingNode = sourceNode;
                    }
                    break;
                }
            }
        };
        [NSThread isMainThread] ? onMain() : dispatch_async(dispatch_get_main_queue(), onMain);
        return;
    }

    [self p_scheduleAfterThrottle:sourceNode newValue:newValue];
}

/// 后沿定时器：窗口结束时尝试补发最后被压制的值
- (void)p_scheduleTrailingWithToken:(NSUInteger)token {
    __weak typeof(self) weak = self;
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.throttleInterval * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
            JHBindingGroup *strongSelf = weak;
            if (!strongSelf) return;
            if (strongSelf->_throttleTrailingToken != token) return; // 令牌过期，窗口已被新事件覆盖

            strongSelf->_throttleWindowActive = NO;
            id pending = strongSelf->_throttlePendingValue;
            JHBindingNode *pendingNode = strongSelf->_throttlePendingNode;
            strongSelf->_throttlePendingValue = nil;
            strongSelf->_throttlePendingNode = nil;

            if (pending && pendingNode) {
                [strongSelf p_scheduleAfterThrottle:pendingNode newValue:pending];
            }
        });
}

/// throttle 通过后，再走 debounce / delay / 直通
- (void)p_scheduleAfterThrottle:(JHBindingNode *)sourceNode newValue:(id)newValue {
    if (self.debounceInterval > 0) {
        // debounce：取消上次待执行 block，重新计时
        // pendingDebounceBlock 只在主线程读写，无需额外锁
        void (^scheduleOnMain)(void) = ^{
            if (self.pendingDebounceBlock) {
                dispatch_block_cancel(self.pendingDebounceBlock);
            }
            __weak typeof(self) weak = self;
            dispatch_block_t block = dispatch_block_create(0, ^{
                weak.pendingDebounceBlock = nil;
                [weak p_doBroadcastFromNode:sourceNode newValue:newValue];
            });
            self.pendingDebounceBlock = block;
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.debounceInterval * NSEC_PER_SEC)),
                dispatch_get_main_queue(), block);
        };
        [NSThread isMainThread] ? scheduleOnMain() : dispatch_async(dispatch_get_main_queue(), scheduleOnMain);
        return;
    }

    if (self.delayInterval > 0) {
        // delay：每次触发都延迟固定时间，不取消前次
        __weak typeof(self) weak = self;
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayInterval * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
                [weak p_doBroadcastFromNode:sourceNode newValue:newValue];
            });
        return;
    }

    [self p_doBroadcastFromNode:sourceNode newValue:newValue];
}

// MARK: - 广播执行（原 p_broadcastFromNode，加 once / log）

- (void)p_doBroadcastFromNode:(JHBindingNode *)sourceNode newValue:(id)newValue {
    // 防跨链循环：本组已在广播中则跳过
    @synchronized (sBroadcastingGroupIDs) {
        if ([sBroadcastingGroupIDs containsObject:self.groupID]) return;
        [sBroadcastingGroupIDs addObject:self.groupID];
    }

    // 线程安全地按插入顺序获取节点快照，保证 receive 先于 observe block 执行
    __block NSArray<JHBindingNode *> *snapshot = nil;
    dispatch_sync(self.queue, ^{
        NSMutableArray *ordered = [NSMutableArray arrayWithCapacity:self->_nodeOrder.count];
        for (NSString *nodeID in self->_nodeOrder) {
            JHBindingNode *n = self->_nodeMap[nodeID];
            if (n) [ordered addObject:n];
        }
        snapshot = ordered.copy;
    });

    // 确保 UI 更新在主线程执行
    void (^broadcastBlock)(void) = ^{
        // skip（v1.4）：前 N 次广播直接跳过
        if (self->_skipRemaining > 0) {
            self->_skipRemaining--;
            @synchronized (sBroadcastingGroupIDs) {
                [sBroadcastingGroupIDs removeObject:self.groupID];
            }
            return;
        }

        // defaultValue（v1.4）：nil / NSNull 替换为默认值
        id effectiveValue = newValue;
        if (self.defaultValue && (!effectiveValue || [effectiveValue isKindOfClass:[NSNull class]])) {
            effectiveValue = self.defaultValue;
        }
        // transform（v1.5）：链级全局値变换
        if (self.transformBlock) {
            effectiveValue = self.transformBlock(effectiveValue);
        }

        // biMap（v1.5）：根据广播源的类型选择方向
        //   sourceNode.isUIControl == YES  → UI 层输入 → 应用 backward（将 UI 値转为模型値）
        //   sourceNode.isUIControl == NO   → 模型/KVO 改变 → 应用 forward（将模型値转为 UI 値）
        if (sourceNode.isUIControl && self.biMapBackwardBlock) {
            effectiveValue = self.biMapBackwardBlock(effectiveValue);
        } else if (!sourceNode.isUIControl && self.biMapForwardBlock) {
            effectiveValue = self.biMapForwardBlock(effectiveValue);
        }

        // scan（v1.5）：累加器
        if (self.scanBlock) {
            self->_scanAccumulated = self.scanBlock(self->_scanAccumulated, effectiveValue);
            effectiveValue = self->_scanAccumulated;
        }

        // withPrevious（v1.5）：双値打包
        if (self.isWithPrevious) {
            id prev = self->_previousBroadcastValue ?: [NSNull null];
            self->_previousBroadcastValue = effectiveValue; // 先更新，安全
            effectiveValue = @[prev, effectiveValue];
        }
        // log：广播日志
        if (self.debugLabel) {
            NSLog(@"[JHBinder:%@] broadcast  %@ → %@", self.debugLabel, sourceNode.nodeID, effectiveValue);
        }

        for (JHBindingNode *node in snapshot) {
            if (node == sourceNode) continue; // 不回传给来源节点
            if (!(node.direction & JHBindDirectionReceive)) continue;

            // 节点级 filter（v1.3）：先于 map 执行，检查原始广播值
            if (node.receiveFilterBlock && !node.receiveFilterBlock(effectiveValue)) continue;

            // 节点级 map（convertBlock）：filter 通过后再转换显示值
            id outValue = effectiveValue;
            if (node.convertBlock) outValue = node.convertBlock(effectiveValue);

            id target = node.target;
            if (target) {
                // 标记更新状态，防止 setValue 触发的 KVO 引起循环
                ((NSObject *)target).jh_isUpdating = YES;
                [target setValue:outValue forKeyPath:node.keyPath];
                ((NSObject *)target).jh_isUpdating = NO;
            }

            // 纯 block 订阅节点（target 为 nil 时也触发）
            if (node.outBlock) node.outBlock(outValue);
        }

        @synchronized (sBroadcastingGroupIDs) {
            [sBroadcastingGroupIDs removeObject:self.groupID];
        }

        // take（v1.4）/ once：广播完成后检查是否需要解绑
        if (self.takeCount > 0) {
            // take(N)：递减剩余次数，归零时解绑
            if (self->_takeRemaining > 0) {
                self->_takeRemaining--;
                if (self->_takeRemaining == 0) {
                    [self removeAllNodes];
                }
            }
        } else if (self.isOnce) {
            // 兼容旧的 isOnce 路径
            [self removeAllNodes];
        }
    };

    if ([NSThread isMainThread]) {
        broadcastBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), broadcastBlock);
    }
}

// MARK: - fire

- (void)fireFromFirstListenNode {
    // 找插入顺序中第一个有监听能力的节点作为广播源
    __block JHBindingNode *firstNode = nil;
    dispatch_sync(self.queue, ^{
        for (NSString *nodeID in self->_nodeOrder) {
            JHBindingNode *node = self->_nodeMap[nodeID];
            if ((node.direction & JHBindDirectionListen) && node.target) {
                firstNode = node;
                break;
            }
        }
    });
    if (!firstNode) return;

    id target = firstNode.target;
    if (!target) return;
    id value = [target valueForKeyPath:firstNode.keyPath];

    // 允许 nil 值广播（用 NSNull 占位，接收节点收到 NSNull 时置 nil）
    if (!value) value = [NSNull null];

    void (^doFire)(void) = ^{ [self p_doBroadcastFromNode:firstNode newValue:value]; };
    [NSThread isMainThread] ? doFire() : dispatch_async(dispatch_get_main_queue(), doFire);
}

@end
