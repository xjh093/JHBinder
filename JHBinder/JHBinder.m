//
//  JHBinder.m
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//

#import "JHBinder.h"
#import "JHBindingGroup.h"
#import "JHBindingNode.h"
#import "JHBindingManager.h"
#import "JHCombineRelay.h"
#import "JHMergeRelay.h"
#import "JHIntervalRelay.h"
#import "NSObject+JHBind.h"
#import <objc/runtime.h>


@interface JHBinder ()

/// 持有的广播组（binder dealloc 时，group 引用归零自动解绑）
@property (nonatomic, strong) JHBindingGroup *group;

/// 对应 manager 中注册的 groupID
@property (nonatomic, copy) NSString *groupID;

/// v1.3：最后一次添加的 Receive 节点，供 .nodeMap() / .nodeFilter() 引用
@property (nonatomic, weak) JHBindingNode *lastReceiveNode;

@end


@implementation JHBinder

// MARK: - 初始化（内部使用）

- (instancetype)initWithGroup:(JHBindingGroup *)group {
    self = [super init];
    if (self) {
        _group = group;
        _groupID = group.groupID;
    }
    return self;
}

- (void)dealloc {
    // binder 释放时从 manager 移除 group，触发 group dealloc → 全部节点解绑
    [[JHBindingManager shared] removeGroupWithID:_groupID];
}

// MARK: - 私有工厂

/// 创建新的 binder（链起始时调用）
+ (JHBinder *)p_newBinder {
    JHBindingGroup *group = [[JHBindingManager shared] createGroup];
    return [[JHBinder alloc] initWithGroup:group];
}

/// 添加节点到本 binder 的 group
- (void)p_addNode:(JHBindingNode *)node {
    [self.group addNode:node];
}


// MARK: - 双向绑定（twoWay）

+ (JHBinderBlock)twoWay {
    return ^JHBinder *(id target, NSString *keyPath) {
        JHBinder *binder = [JHBinder p_newBinder];
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                          direction:JHBindDirectionBoth
                                                       convertBlock:nil];
        [binder p_addNode:node];
        return binder;
    };
}

+ (JHBinderUIBlock)twoWayUI {
    return ^JHBinder *(id target, NSString *keyPath, UIControlEvents event) {
        JHBinder *binder = [JHBinder p_newBinder];
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                       controlEvent:event
                                                          direction:JHBindDirectionBoth
                                                       convertBlock:nil];
        [binder p_addNode:node];
        return binder;
    };
}

+ (JHBinderConvertBlock)twoWayMap {
    return ^JHBinder *(id target, NSString *keyPath, JHConvertBlock convert) {
        JHBinder *binder = [JHBinder p_newBinder];
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                          direction:JHBindDirectionBoth
                                                       convertBlock:convert];
        [binder p_addNode:node];
        return binder;
    };
}

+ (JHBinderUIConvertBlock)twoWayUIMap {
    return ^JHBinder *(id target, NSString *keyPath, UIControlEvents event, JHConvertBlock convert) {
        JHBinder *binder = [JHBinder p_newBinder];
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                       controlEvent:event
                                                          direction:JHBindDirectionBoth
                                                       convertBlock:convert];
        [binder p_addNode:node];
        return binder;
    };
}

- (JHBinderBlock)twoWay {
    return ^JHBinder *(id target, NSString *keyPath) {
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                          direction:JHBindDirectionBoth
                                                       convertBlock:nil];
        [self p_addNode:node];
        return self;
    };
}

- (JHBinderUIBlock)twoWayUI {
    return ^JHBinder *(id target, NSString *keyPath, UIControlEvents event) {
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                       controlEvent:event
                                                          direction:JHBindDirectionBoth
                                                       convertBlock:nil];
        [self p_addNode:node];
        return self;
    };
}

- (JHBinderConvertBlock)twoWayMap {
    return ^JHBinder *(id target, NSString *keyPath, JHConvertBlock convert) {
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                          direction:JHBindDirectionBoth
                                                       convertBlock:convert];
        [self p_addNode:node];
        return self;
    };
}

- (JHBinderUIConvertBlock)twoWayUIMap {
    return ^JHBinder *(id target, NSString *keyPath, UIControlEvents event, JHConvertBlock convert) {
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                       controlEvent:event
                                                          direction:JHBindDirectionBoth
                                                       convertBlock:convert];
        [self p_addNode:node];
        return self;
    };
}


// MARK: - 单向监听（listen）

+ (JHBinderBlock)listen {
    return ^JHBinder *(id target, NSString *keyPath) {
        JHBinder *binder = [JHBinder p_newBinder];
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                          direction:JHBindDirectionListen
                                                       convertBlock:nil];
        [binder p_addNode:node];
        return binder;
    };
}

+ (JHBinderUIBlock)listenUI {
    return ^JHBinder *(id target, NSString *keyPath, UIControlEvents event) {
        JHBinder *binder = [JHBinder p_newBinder];
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                       controlEvent:event
                                                          direction:JHBindDirectionListen
                                                       convertBlock:nil];
        [binder p_addNode:node];
        return binder;
    };
}

- (JHBinderBlock)listen {
    return ^JHBinder *(id target, NSString *keyPath) {
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                          direction:JHBindDirectionListen
                                                       convertBlock:nil];
        [self p_addNode:node];
        return self;
    };
}

- (JHBinderUIBlock)listenUI {
    return ^JHBinder *(id target, NSString *keyPath, UIControlEvents event) {
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                       controlEvent:event
                                                          direction:JHBindDirectionListen
                                                       convertBlock:nil];
        [self p_addNode:node];
        return self;
    };
}


// MARK: - 单向接收（receive）

- (JHBinderBlock)receive {
    return ^JHBinder *(id target, NSString *keyPath) {
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                          direction:JHBindDirectionReceive
                                                       convertBlock:nil];
        [self p_addNode:node];
        self.lastReceiveNode = node;  // v1.3
        return self;
    };
}

- (JHBinderConvertBlock)receiveMap {
    return ^JHBinder *(id target, NSString *keyPath, JHConvertBlock convert) {
        JHBindingNode *node = [[JHBindingNode alloc] initWithTarget:target
                                                            keyPath:keyPath
                                                          direction:JHBindDirectionReceive
                                                       convertBlock:convert];
        [self p_addNode:node];
        self.lastReceiveNode = node;  // v1.3
        return self;
    };
}

- (JHBinderObserveBlock)observe {
    return ^JHBinder *(NSString *key, JHOutBlock handler) {
        JHBindingNode *node = [JHBindingNode nodeWithOutBlock:handler key:key];
        [self p_addNode:node];
        return self;
    };
}


// MARK: - 过滤 / 存储

- (JHBinderFilterBlock)filter {
    return ^JHBinder *(JHFilterBlock filterBlock) {
        [self.group setFilterBlock:filterBlock];
        return self;
    };
}

- (JHBinderStoreBlock)store {
    return ^(NSMutableArray *array) {
        // 将 self 存入调用方数组，由调用方管理生命周期
        // 调用方（如 vc）持有该数组；vc 销毁时，数组释放 → binder dealloc → 自动解绑
        [array addObject:self];
    };
}


// MARK: - 显式解绑（全局）

+ (void)unbindTarget:(id)target {
    [[JHBindingManager shared] unbindTarget:target];
}

+ (void)unbindTarget:(id)target keyPath:(NSString *)keyPath {
    [[JHBindingManager shared] unbindTarget:target keyPath:keyPath];
}

+ (BOOL)isBound:(id)target keyPath:(NSString *)keyPath {
    return [[JHBindingManager shared] isTarget:target boundForKeyPath:keyPath];
}


// MARK: - v1.2 新增：广播行为控制

- (JHBinderVoidBlock)fire {
    return ^JHBinder *{
        [self.group fireFromFirstListenNode];
        return self;
    };
}

- (JHBinderVoidBlock)distinct {
    return ^JHBinder *{
        self.group.isDistinct = YES;
        return self;
    };
}

- (JHBinderVoidBlock)once {
    return ^JHBinder *{
        // once 复用 take(1) 的实现路径
        self.group.takeCount = 1;
        return self;
    };
}

- (JHBinderIntervalBlock)debounce {
    return ^JHBinder *(NSTimeInterval interval) {
        self.group.debounceInterval = interval;
        return self;
    };
}

- (JHBinderIntervalBlock)delay {
    return ^JHBinder *(NSTimeInterval interval) {
        self.group.delayInterval = interval;
        return self;
    };
}

- (JHBinderLabelBlock)log {
    return ^JHBinder *(NSString *label) {
        self.group.debugLabel = label;
        return self;
    };
}


// MARK: - v1.4 新增：广播流控制

- (JHBinderDefaultBlock)defaultValue {
    return ^JHBinder *(id value) {
        self.group.defaultValue = value;
        return self;
    };
}

- (JHBinderCountBlock)skip {
    return ^JHBinder *(NSUInteger count) {
        self.group.skipCount = count;
        return self;
    };
}

- (JHBinderCountBlock)take {
    return ^JHBinder *(NSUInteger count) {
        self.group.takeCount = count;
        return self;
    };
}

- (JHBinderIntervalBlock)throttle {
    return ^JHBinder *(NSTimeInterval interval) {
        self.group.throttleInterval = interval;
        // throttleMode 默认为 JHThrottleModeLead，无需显式设置
        return self;
    };
}

- (JHBinderIntervalBlock)throttleTrailing {
    return ^JHBinder *(NSTimeInterval interval) {
        self.group.throttleInterval = interval;
        self.group.throttleMode = JHThrottleModeLeadTrail;
        return self;
    };
}

- (JHBinderIntervalBlock)throttleTrailingOnly {
    return ^JHBinder *(NSTimeInterval interval) {
        self.group.throttleInterval = interval;
        self.group.throttleMode = JHThrottleModeTrail;
        return self;
    };
}

// MARK: - v1.5 值变换扩展

- (JHBinderTransformBlock)transform {
    return ^JHBinder *(JHConvertBlock convert) {
        self.group.transformBlock = convert;
        return self;
    };
}

- (JHBinderScanBlock)scan {
    return ^JHBinder *(id initialValue, JHAccumulateBlock accumulator) {
        self.group.scanInitialValue = initialValue;
        self.group.scanBlock = accumulator;
        return self;
    };
}

- (JHBinderVoidBlock)withPrevious {
    return ^JHBinder *{
        self.group.isWithPrevious = YES;
        return self;
    };
}

- (JHBinderBiMapBlock)biMap {
    return ^JHBinder *(JHConvertBlock forward, JHConvertBlock backward) {
        self.group.biMapForwardBlock  = forward;
        self.group.biMapBackwardBlock = backward;
        return self;
    };
}

- (JHBinderNodeMapBlock)nodeMap {
    return ^JHBinder *(JHConvertBlock convert) {
        self.lastReceiveNode.convertBlock = convert;
        return self;
    };
}

- (JHBinderNodeFilterBlock)nodeFilter {
    return ^JHBinder *(JHNodeFilterBlock filter) {
        self.lastReceiveNode.receiveFilterBlock = filter;
        return self;
    };
}


// MARK: - v1.3 新增：combineLatest

+ (JHBinder *)combineLatest:(NSArray<JHBinder *> *)sources
                 combineMap:(id _Nullable (^)(NSArray *))combineBlock {
    NSUInteger count = sources.count;
    NSAssert(count > 0, @"JHBinder.combineLatest: sources 不能为空");

    JHCombineRelay *relay = [[JHCombineRelay alloc] initWithCount:count
                                                     combineBlock:combineBlock];

    // 为每个 source 注入 outBlock 节点，发射时通知 relay
    for (NSUInteger i = 0; i < count; i++) {
        JHBinder *source = sources[i];
        NSUInteger idx = i;
        __weak JHCombineRelay *weakRelay = relay;
        NSString *key = [NSString stringWithFormat:@"_jh_combine_%lu", (unsigned long)idx];
        JHBindingNode *node = [JHBindingNode nodeWithOutBlock:^(id _Nullable value) {
            [weakRelay updateValue:value atIndex:idx];
        } key:key];
        [source.group addNode:node];
    }

    // combine binder 监听 relay.result（KVO），result 变化时向下游广播
    JHBinder *combineBinder = [JHBinder p_newBinder];
    JHBindingNode *listenNode = [[JHBindingNode alloc] initWithTarget:relay
                                                              keyPath:@"result"
                                                            direction:JHBindDirectionListen
                                                         convertBlock:nil];
    [combineBinder p_addNode:listenNode];

    // combine binder 强持有 sources 和 relay，保证生命周期
    objc_setAssociatedObject(combineBinder, @"_jh_sources", sources, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(combineBinder, @"_jh_relay",   relay,   OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return combineBinder;
}


// MARK: - v1.6 新增：merge

+ (JHBinder *)merge:(NSArray<JHBinder *> *)sources {
    NSAssert(sources.count > 0, @"JHBinder.merge: sources 不能为空");

    // 创建一个轻量中转对象：任意源触发时把值写入 relay.result，
    // merge binder KVO 监听 relay.result，任一源发射即广播
    JHMergeRelay *relay = [JHMergeRelay new];

    for (NSUInteger i = 0; i < sources.count; i++) {
        JHBinder *source = sources[i];
        __weak JHMergeRelay *weakRelay = relay;
        NSString *key = [NSString stringWithFormat:@"_jh_merge_%lu", (unsigned long)i];
        JHBindingNode *node = [JHBindingNode nodeWithOutBlock:^(id _Nullable value) {
            weakRelay.result = value;
        } key:key];
        [source.group addNode:node];
    }

    // merge binder 监听 relay.result
    JHBinder *mergeBinder = [JHBinder p_newBinder];
    JHBindingNode *listenNode = [[JHBindingNode alloc] initWithTarget:relay
                                                              keyPath:@"result"
                                                            direction:JHBindDirectionListen
                                                         convertBlock:nil];
    [mergeBinder p_addNode:listenNode];

    // 强持有 sources 和 relay，保证生命周期
    objc_setAssociatedObject(mergeBinder, @"_jh_merge_sources", sources, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(mergeBinder, @"_jh_merge_relay",   relay,   OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return mergeBinder;
}


// MARK: - v1.6 流控扩展

- (JHBinderDefaultBlock)startWith {
    return ^JHBinder *(id value) {
        [self.group fireFromFirstListenNodeWithValue:value];
        return self;
    };
}

- (JHBinderTapBlock)tap {
    return ^JHBinder *(JHOutBlock handler) {
        [self.group addTapBlock:handler];
        return self;
    };
}

- (JHBinderVoidBlock)negate {
    return ^JHBinder *{
        JHConvertBlock existing = self.group.transformBlock;
        if (existing) {
            JHConvertBlock captured = existing;
            self.group.transformBlock = ^id(id v){ return @(![captured(v) boolValue]); };
        } else {
            self.group.transformBlock = ^id(id v){ return @(![v boolValue]); };
        }
        return self;
    };
}

- (JHBinderDefaultBlock)mapTo {
    return ^JHBinder *(id value) {
        self.group.transformBlock = ^id(id __unused v){ return value; };
        return self;
    };
}

- (JHBinderFilterBlock)distinctWhen {
    return ^JHBinder *(JHFilterBlock comparator) {
        self.group.isDistinct = YES;
        self.group.distinctComparatorBlock = comparator;
        return self;
    };
}

- (JHBinderPredicateBlock)takeWhile {
    return ^JHBinder *(JHNodeFilterBlock predicate) {
        self.group.takeWhileBlock = predicate;
        return self;
    };
}

- (JHBinderPredicateBlock)skipWhile {
    return ^JHBinder *(JHNodeFilterBlock predicate) {
        self.group.skipWhileBlock = predicate;
        return self;
    };
}

- (JHBinderWithLatestFromBlock)withLatestFrom {
    return ^JHBinder *(JHBinder *other) {
        self.group.sampleGroup = other.group;
        // 强持有 other binder，防止过早释放
        objc_setAssociatedObject(self, "_jh_wlf_other", other, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return self;
    };
}

// MARK: - v1.7 类方法：interval

+ (JHBinderIntervalBlock)interval {
    return ^JHBinder *(NSTimeInterval t) {
        return [JHBinder intervalBinder:t];
    };
}

+ (JHBinder *)intervalBinder:(NSTimeInterval)interval {
    JHIntervalRelay *relay = [JHIntervalRelay new];
    // 用现有 listen 机制监听 relay.tick（KVO）
    JHBinder *binder = JHBinder.listen(relay, @"tick");
    // 强持有 relay，使其生命周期与 binder 相同
    objc_setAssociatedObject(binder, "_jh_interval_relay", relay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [relay startWithInterval:interval];
    return binder;
}

// MARK: - v1.7 实例操作符

- (JHBinderWithLatestFromBlock)takeUntil {
    return ^JHBinder *(JHBinder *signal) {
        __weak JHBindingGroup *weakGroup = self.group;
        // 在 signal 的 group 上注册一个 receive-only outBlock 节点
        // 当 signal 广播时，outBlock 触发，解绑当前链
        static NSUInteger _seqNum = 0;
        NSString *key = [NSString stringWithFormat:@"_jh_takeUntil_%lu", (unsigned long)++_seqNum];
        JHBindingNode *node = [JHBindingNode nodeWithOutBlock:^(id __unused v) {
            JHBindingGroup *strong = weakGroup;
            [strong removeAllNodes];
        } key:key];
        [signal.group addNode:node];
        // 强持有 signal binder，防止 signal 先于 self 释放
        objc_setAssociatedObject(self, "_jh_takeUntil_sig", signal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return self;
    };
}

- (JHBinderPluckBlock)pluck {
    return ^JHBinder *(NSString *keyPath) {
        NSString *kp = keyPath;
        JHConvertBlock existing = self.group.transformBlock;
        if (existing) {
            JHConvertBlock captured = existing;
            self.group.transformBlock = ^id(id v) {
                id intermediate = captured(v);
                @try { return [intermediate valueForKeyPath:kp]; }
                @catch (...) { return nil; }
            };
        } else {
            self.group.transformBlock = ^id(id v) {
                @try { return [v valueForKeyPath:kp]; }
                @catch (...) { return nil; }
            };
        }
        return self;
    };
}

- (JHBinderCountBlock)bufferCount {
    return ^JHBinder *(NSUInteger n) {
        self.group.bufferCountValue = n;
        return self;
    };
}

- (JHBinderIntervalBlock)bufferTime {
    return ^JHBinder *(NSTimeInterval t) {
        self.group.bufferTimeInterval = t;
        return self;
    };
}

- (JHBinderTimeoutBlock)timeout {
    return ^JHBinder *(NSTimeInterval t, id _Nullable fallback) {
        self.group.timeoutFallback = fallback;
        self.group.timeoutInterval = t; // setter 内部自动启动计时器
        return self;
    };
}

- (JHBinderIntervalBlock)sample {
    return ^JHBinder *(NSTimeInterval t) {
        self.group.sampleInterval = t; // setter 内部自动启动采样定时器
        return self;
    };
}

- (JHBinderCombineBlock)combine {
    return ^JHBinder *(JHBinder *other, id _Nullable (^combineMap)(NSArray *values)) {
        return [JHBinder combineLatest:@[self, other] combineMap:combineMap];
    };
}

- (JHBinderCountBlock)elementAt {
    return ^JHBinder *(NSUInteger n) {
        NSAssert(n >= 1, @"elementAt: n must be >= 1");
        if (n > 1) self.group.skipCount = n - 1;
        self.group.takeCount = 1;
        return self;
    };
}

@end
