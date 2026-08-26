//
//  JHBindingManager.m
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//

#import "JHBindingManager.h"
#import "JHBindingGroup.h"
#import "JHBindingNode.h"
#import "NSObject+JHBind.h"

@interface JHBindingManager ()

/// groupID → JHBindingGroup，使用并发队列 + barrier 保证线程安全
@property (nonatomic, strong) NSMutableDictionary<NSString *, JHBindingGroup *> *groupMap;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation JHBindingManager

// MARK: - 单例

+ (instancetype)shared {
    static JHBindingManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JHBindingManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _groupMap = [NSMutableDictionary dictionary];
        _queue = dispatch_queue_create("com.jhbinder.manager", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

// MARK: - Group 生命周期

- (JHBindingGroup *)createGroup {
    NSString *groupID = [[NSUUID UUID] UUIDString];
    JHBindingGroup *group = [[JHBindingGroup alloc] initWithGroupID:groupID];

    dispatch_barrier_async(self.queue, ^{
        self->_groupMap[groupID] = group;
    });
    return group;
}

- (nullable JHBindingGroup *)groupWithID:(NSString *)groupID {
    __block JHBindingGroup *group = nil;
    dispatch_sync(self.queue, ^{
        group = self->_groupMap[groupID];
    });
    return group;
}

- (void)removeGroupWithID:(NSString *)groupID {
    // 用 __block 把 group 取出到局部变量，让它在 barrier 之外（调用方线程）释放
    // 从而保证 group.dealloc → p_stopObservingNode 在调用方线程（通常是主线程）执行
    // 若改为 dispatch_barrier_async，group 会在后台队列 dealloc，导致 UIControl 操作非主线程崩溃
    __block JHBindingGroup *groupToRelease = nil;
    dispatch_barrier_sync(self.queue, ^{
        groupToRelease = self->_groupMap[groupID];
        [self->_groupMap removeObjectForKey:groupID];
    });
    // groupToRelease 在此处（调用方线程）释放，触发 group.dealloc
    groupToRelease = nil;
}

// MARK: - 解绑

- (void)unbindTarget:(id)target {
    NSString *targetHash = [(NSObject *)target jh_hash];

    __block NSArray<JHBindingGroup *> *snapshot = nil;
    dispatch_sync(self.queue, ^{
        snapshot = self->_groupMap.allValues.copy;
    });

    for (JHBindingGroup *group in snapshot) {
        // 遍历所有 group，移除包含此 target 的节点
        // 由于 group 内部有线程保护，这里直接调用即可
        [self p_removeNodesForTargetHash:targetHash keyPath:nil inGroup:group];
    }
}

- (void)unbindTarget:(id)target keyPath:(NSString *)keyPath {
    NSString *targetHash = [(NSObject *)target jh_hash];
    NSString *nodeID = [NSString stringWithFormat:@"%@_%@", targetHash, keyPath];

    __block NSArray<JHBindingGroup *> *snapshot = nil;
    dispatch_sync(self.queue, ^{
        snapshot = self->_groupMap.allValues.copy;
    });

    for (JHBindingGroup *group in snapshot) {
        [group removeNodeWithID:nodeID];
    }
}

// MARK: - 查询

- (BOOL)isTarget:(id)target boundForKeyPath:(NSString *)keyPath {
    NSString *targetHash = [(NSObject *)target jh_hash];

    __block NSArray<JHBindingGroup *> *snapshot = nil;
    dispatch_sync(self.queue, ^{
        snapshot = self->_groupMap.allValues.copy;
    });

    for (JHBindingGroup *group in snapshot) {
        if ([group containsNodeForTargetHash:targetHash keyPath:keyPath]) {
            return YES;
        }
    }
    return NO;
}

// MARK: - 私有

/// keyPath 为 nil 时移除 target 下所有节点
- (void)p_removeNodesForTargetHash:(NSString *)targetHash
                           keyPath:(nullable NSString *)keyPath
                           inGroup:(JHBindingGroup *)group {
    if (keyPath) {
        NSString *nodeID = [NSString stringWithFormat:@"%@_%@", targetHash, keyPath];
        [group removeNodeWithID:nodeID];
    } else {
        // 移除 target 下所有 keyPath 的节点
        // 约定 nodeID 格式为 "targetHash_keyPath"，以 targetHash 为前缀匹配
        [group removeNodesForTargetHash:targetHash];
    }
}

@end
