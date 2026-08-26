//
//  BasicDemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  演示：Model ↔ UITextField ↔ Label 的双向绑定
//  JHBinder API：twoWay / twoWayUI / receive / observe / store
//

#import "BasicDemoViewController.h"
#import "BasicDemoView.h"
#import "BasicDemoModel.h"
#import "JHBinderKit.h"

@interface BasicDemoViewController ()

@property (nonatomic, strong) BasicDemoView  *demoView;
@property (nonatomic, strong) BasicDemoModel *model;
@property (nonatomic, strong) NSMutableArray *bindings; ///< 持有 binder，vc 销毁自动解绑

@end

@implementation BasicDemoViewController

// MARK: - Lifecycle

- (void)loadView {
    self.view = [[BasicDemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self p_initData];
    [self p_bindData];
    [self p_setupActions];
}

// MARK: - Setup

- (void)p_initData {
    self.demoView  = (BasicDemoView *)self.view;
    self.model     = [[BasicDemoModel alloc] init];
    self.bindings  = [NSMutableArray array];
}

- (void)p_bindData {
    __weak __typeof(self) weak = self;

    // 绑定链：
    //   model.text（双向，KVO 监听）
    //     ↔ textField.text（双向，UIControlEventEditingChanged 驱动）
    //     → syncLabel.text（单向接收）
    //     → observe block（值变化时打印日志）
    JHBinder
        .twoWay(self.model, @"text")
        .twoWayUI(self.demoView.textField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.syncLabel, @"text")
        .observe(@"basic.text.changed", ^(id value) {
            NSLog(@"[BasicDemo] model.text = %@  |  from observe block", weak.model.text);
        })
        .store(self.bindings);
}

- (void)p_setupActions {
    [self.demoView.setValueBtn addTarget:self
                                  action:@selector(p_onSetValueTapped)
                        forControlEvents:UIControlEventTouchUpInside];
}

// MARK: - Actions

- (void)p_onSetValueTapped {
    // 直接修改 Model 属性，JHBinder 会自动同步到 textField 和 syncLabel
    self.model.text = @"Hello JHBinder";
}

@end
