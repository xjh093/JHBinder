//
//  V16DemoModel.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface V16DemoModel : NSObject

// ① merge：两个字段任意变化都触发校验
@property (nonatomic, copy, nullable) NSString *username;
@property (nonatomic, copy, nullable) NSString *password;

// ② withLatestFrom：关键词 + 分类
@property (nonatomic, copy, nullable) NSString *searchKeyword;
@property (nonatomic, copy, nullable) NSString *searchCategory;

// ③ startWith：初始状态文字
@property (nonatomic, copy, nullable) NSString *statusText;

// ④ tap：埋点计数器（model 内不直接用，VC 里的 tap 演示）
@property (nonatomic, copy, nullable) NSString *tapDemoText;

// ⑤ negate：isLoading 状态
@property (nonatomic, assign) BOOL isLoading;

// ⑥ mapTo：任意变化都映射到固定值
@property (nonatomic, copy, nullable) NSString *anyChangeText;

// ⑦ distinctWhen：忽略大小写去重
@property (nonatomic, copy, nullable) NSString *caseText;

// ⑧ takeWhile / skipWhile：计数器
@property (nonatomic, strong, nullable) NSNumber *counter;

@end

NS_ASSUME_NONNULL_END
