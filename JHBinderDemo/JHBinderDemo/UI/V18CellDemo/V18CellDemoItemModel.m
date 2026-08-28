//
//  V18CellDemoItemModel.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/28/26.
//

#import "V18CellDemoItemModel.h"

@implementation V18CellDemoItemModel

+ (NSMutableArray<V18CellDemoItemModel *> *)makeList:(NSUInteger)count {
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 1; i <= count; i++) {
        V18CellDemoItemModel *m = [V18CellDemoItemModel new];
        m.name     = [NSString stringWithFormat:@"Item %02lu", (unsigned long)i];
        m.tapCount = @0;
        [list addObject:m];
    }
    return list;
}

@end
