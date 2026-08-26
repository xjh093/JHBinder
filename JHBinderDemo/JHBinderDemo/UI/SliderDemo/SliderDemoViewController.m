//
//  SliderDemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  演示：
//    - UISlider ↔ model.sliderValue（双向，UIControlEventValueChanged）
//    - receiveMap：NSNumber → 百分比字符串 → valueLabel.text
//    - receiveMap：NSNumber → NSNumber（同值）→ progressView.progress
//    - 按钮直接修改 model，验证单向 → UI 同步
//

#import "SliderDemoViewController.h"
#import "SliderDemoView.h"
#import "SliderDemoModel.h"
#import "JHBinderKit.h"

@interface SliderDemoViewController ()

@property (nonatomic, strong) SliderDemoView  *demoView;
@property (nonatomic, strong) SliderDemoModel *model;
@property (nonatomic, strong) NSMutableArray  *bindings;

@end

@implementation SliderDemoViewController

- (void)loadView {
    self.view = [[SliderDemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demoView = (SliderDemoView *)self.view;
    self.model    = [[SliderDemoModel alloc] init];
    self.bindings = [NSMutableArray array];
    [self p_bindData];
    [self p_setupActions];

    // 初始值
    self.model.sliderValue = 0.3f;
}

- (void)p_bindData {
    JHBinder
        .twoWay(self.model, @"sliderValue")
    
        // UISlider 用 twoWayUI，value 为 float，JHBinder 通过 KVC 以 NSNumber 传递
        .twoWayUI(self.demoView.slider, @"value", UIControlEventValueChanged)
    
        // receiveMap：NSNumber(float) → 百分比字符串
        .receiveMap(self.demoView.valueLabel, @"text", ^id(NSNumber *value) {
            return [NSString stringWithFormat:@"%.0f%%", value.floatValue * 100];
        })
    
        // receiveMap：NSNumber → NSNumber（progress 范围 0~1 与 model 相同，直接传递）
        .receiveMap(self.demoView.progressView, @"progress", ^id(NSNumber *value) {
            return value; // UIProgressView.progress 是 float，KVC 接受 NSNumber
        })
        .store(self.bindings);
}

- (void)p_setupActions {
    [self.demoView.randomBtn addTarget:self
                                action:@selector(p_onRandomTapped)
                      forControlEvents:UIControlEventTouchUpInside];
}

- (void)p_onRandomTapped {
    // 代码直接写入 model，验证 KVO → UI 同步路径
    self.model.sliderValue = (float)arc4random_uniform(101) / 100.f;
}

@end
