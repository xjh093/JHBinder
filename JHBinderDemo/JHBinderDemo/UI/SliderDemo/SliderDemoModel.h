//
//  SliderDemoModel.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  演示：UISlider ↔ Model，并通过 receiveMap 同步到 Label（格式化）和 ProgressView
//

#import <Foundation/Foundation.h>

@interface SliderDemoModel : NSObject

/// 范围 [0.0, 1.0]，对应 UISlider 的 value
@property (nonatomic, assign) float sliderValue;

@end
