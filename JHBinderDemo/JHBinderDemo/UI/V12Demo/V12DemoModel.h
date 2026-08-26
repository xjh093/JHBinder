//
//  V12DemoModel.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/26/26.
//
//  演示 v1.2 新特性：fire / debounce / delay / distinct / once
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface V12DemoModel : NSObject

@property (nonatomic, copy) NSString *fireText;      ///< fire 演示：预设初始值
@property (nonatomic, copy) NSString *debounceText;  ///< debounce 演示
@property (nonatomic, copy) NSString *delayText;     ///< delay 演示
@property (nonatomic, copy) NSString *distinctText;  ///< distinct 演示
@property (nonatomic, copy) NSString *onceText;      ///< once 演示

@end

NS_ASSUME_NONNULL_END
