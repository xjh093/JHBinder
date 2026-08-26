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
#import "NSObject+JHBind.h"


@interface JHBinder ()

/// 持有的广播组（binder dealloc 时，group 引用归零自动解绑）
@property (nonatomic, strong) JHBindingGroup *group;

/// 对应 manager 中注册的 groupID
@property (nonatomic, copy) NSString *groupID;

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
        self.group.isOnce = YES;
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

@end
