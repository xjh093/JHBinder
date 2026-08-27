//
//  V14DemoModel.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface V14DemoModel : NSObject
@property (nonatomic, copy, nullable) NSString *defaultText;            ///< defaultValue 演示
@property (nonatomic, copy, nullable) NSString *skipText;               ///< skip 演示
@property (nonatomic, copy, nullable) NSString *takeText;               ///< take 演示
@property (nonatomic, copy, nullable) NSString *throttleText;           ///< throttle（前沿）演示
@property (nonatomic, copy, nullable) NSString *throttleTrailingText;   ///< throttleTrailing（前沿+后沿）演示
@property (nonatomic, copy, nullable) NSString *throttleTrailingOnlyText; ///< throttleTrailingOnly（后沿）演示
@end

NS_ASSUME_NONNULL_END
