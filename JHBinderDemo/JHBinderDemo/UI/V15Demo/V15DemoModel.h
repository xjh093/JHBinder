//
//  V15DemoModel.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface V15DemoModel : NSObject
@property (nonatomic, copy, nullable) NSString *transformText;    ///< transform 演示
@property (nonatomic, copy, nullable) NSString *scanText;         ///< scan 演示
@property (nonatomic, copy, nullable) NSString *withPreviousText; ///< withPrevious 演示
@property (nonatomic, strong) NSNumber *countValue;               ///< biMap 演示（NSNumber ↔ NSString）
@end

NS_ASSUME_NONNULL_END
