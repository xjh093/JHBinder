//
//  SliderDemoView.h
//

#import <UIKit/UIKit.h>

@interface SliderDemoView : UIView

@property (nonatomic, strong, readonly) UILabel        *valueLabel;     ///< 显示当前百分比
@property (nonatomic, strong, readonly) UISlider       *slider;
@property (nonatomic, strong, readonly) UIProgressView *progressView;
@property (nonatomic, strong, readonly) UIButton       *randomBtn;      ///< 随机修改 model.sliderValue

@end
