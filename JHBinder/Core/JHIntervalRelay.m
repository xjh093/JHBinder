//
//  JHIntervalRelay.m
//  JHBinder
//
//  Created by Haomissyou on 8/27/26.
//

#import "JHIntervalRelay.h"

@implementation JHIntervalRelay {
    dispatch_source_t _timer;
    NSUInteger        _count;
}

- (void)startWithInterval:(NSTimeInterval)interval {
    NSAssert(!_timer, @"JHIntervalRelay: startWithInterval: should be called only once");
    _count = 0;
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    uint64_t ns = (uint64_t)(interval * NSEC_PER_SEC);
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)ns), ns, 0);
    __weak typeof(self) weak = self;
    dispatch_source_set_event_handler(_timer, ^{
        typeof(self) strong = weak;
        if (!strong) return;
        strong.tick = @(strong->_count++);
    });
    dispatch_resume(_timer);
}

- (void)invalidate {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

- (void)dealloc {
    [self invalidate];
}

@end
