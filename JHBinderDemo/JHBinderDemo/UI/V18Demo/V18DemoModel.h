//
//  V18DemoModel.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/28/26.
//
//  v1.8 新特性演示模型
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface V18DemoModel : NSObject

// ① format
@property (nonatomic, strong, nullable) NSNumber *price;      ///< 浮点价格 → ¥%.2f
@property (nonatomic, strong, nullable) NSNumber *itemCount;  ///< 件数 → 共 %@ 件

// ② notNil
@property (nonatomic, strong, nullable) id notNilValue;       ///< nil / NSNull / 有效值

// ③ required
@property (nonatomic, copy, nullable) NSString *emailInput;   ///< nil / "" / 非空字符串

// ④ pausable
@property (nonatomic, strong, nullable) NSNumber *isLoggedIn; ///< gate 信号
@property (nonatomic, copy, nullable) NSString *loggedContent;///< 只在已登录时同步

// ⑤ rebind（两个 card 共用同名 keyPath @"cardName"）
@property (nonatomic, copy, nullable) NSString *cardName;

@end

NS_ASSUME_NONNULL_END
