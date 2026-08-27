//
//  JHCombineRelay.m
//  Haomissyou
//
//  Created by Haomissyou on 8/26/26.
//

#import "JHCombineRelay.h"

@implementation JHCombineRelay {
    NSMutableArray  *_latestValues;   ///< 每个 source 的最新值，初始为 NSNull
    NSUInteger       _filledCount;    ///< 已至少发射过一次的 source 数量
    NSUInteger       _totalCount;     ///< source 总数
    id _Nullable     (^_combineBlock)(NSArray *);
}

- (instancetype)initWithCount:(NSUInteger)count
                 combineBlock:(id _Nullable (^)(NSArray *))combineBlock {
    self = [super init];
    if (self) {
        _totalCount   = count;
        _filledCount  = 0;
        _combineBlock = [combineBlock copy];
        _latestValues = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger i = 0; i < count; i++) {
            [_latestValues addObject:[NSNull null]];
        }
    }
    return self;
}

- (void)updateValue:(nullable id)value atIndex:(NSUInteger)index {
    id safeValue = value ?: [NSNull null];

    id combined = nil;
    BOOL shouldFire = NO;

    @synchronized (self) {
        id old = _latestValues[index];
        if ([old isKindOfClass:[NSNull class]]) {
            _filledCount++;
        }
        _latestValues[index] = safeValue;

        if (_filledCount < _totalCount) return; // 尚有 source 未发射，等待

        NSArray *snapshot = [_latestValues copy];
        combined  = _combineBlock ? _combineBlock(snapshot) : snapshot.firstObject;
        shouldFire = YES;
    }

    if (!shouldFire) return;

    // 确保 result 赋值（KVO 触发）在主线程
    void (^doSet)(void) = ^{ self.result = combined; };
    [NSThread isMainThread] ? doSet() : dispatch_async(dispatch_get_main_queue(), doSet);
}

@end
