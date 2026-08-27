//
//  V13DemoModel.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/26/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface V13DemoModel : NSObject

/// nodeFilter 演示：同一文本源分流到"长文本"/"短文本"两个节点
@property (nonatomic, copy, nullable) NSString *filterText;

/// combineLatest 演示：姓名合并
@property (nonatomic, copy, nullable) NSString *firstName;
@property (nonatomic, copy, nullable) NSString *lastName;

@end

NS_ASSUME_NONNULL_END
