//
//  V12DemoView.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/26/26.
//
//  布局（从上到下）：
//    fire()     — label 立即显示模型初始值
//    debounce() — TextField + 结果标签 + 广播次数（debounce 后才递增）
//    delay()    — TextField + 结果标签（延迟 0.5s 才更新）
//    distinct() — TextField + 结果标签 + 广播次数（重复值不递增）
//    once()     — TextField + 结果标签（仅首次更新，之后冻结）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface V12DemoView : UIView

// fire
@property (nonatomic, strong, readonly) UILabel *fireLabel;

// debounce
@property (nonatomic, strong, readonly) UITextField *debounceField;
@property (nonatomic, strong, readonly) UILabel     *debounceResultLabel;
@property (nonatomic, strong, readonly) UILabel     *debounceCountLabel;

// delay
@property (nonatomic, strong, readonly) UITextField *delayField;
@property (nonatomic, strong, readonly) UILabel     *delayResultLabel;

// distinct
@property (nonatomic, strong, readonly) UITextField *distinctField;
@property (nonatomic, strong, readonly) UILabel     *distinctResultLabel;
@property (nonatomic, strong, readonly) UILabel     *distinctCountLabel;

// once
@property (nonatomic, strong, readonly) UITextField *onceField;
@property (nonatomic, strong, readonly) UILabel     *onceResultLabel;

@end

NS_ASSUME_NONNULL_END
