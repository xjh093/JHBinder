//
//  NSObject+JHBind.m
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//

#import "NSObject+JHBind.h"
#import <objc/runtime.h>

@implementation NSObject (JHBind)

// MARK: - jh_hash

- (NSString *)jh_hash {
    return [NSString stringWithFormat:@"%lx", (unsigned long)self.hash];
}

// MARK: - jh_isUpdating（关联对象）

- (BOOL)jh_isUpdating {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setJh_isUpdating:(BOOL)jh_isUpdating {
    objc_setAssociatedObject(self,
                             @selector(jh_isUpdating),
                             @(jh_isUpdating),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
