//
//  ConvertDemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  演示 twoWayMap 的核心特性：
//    convertBlock 只在【接收广播时】执行，广播出去时传原始值
//
//  绑定链（四个节点共用一个 group）：
//
//    model.text  ←→  rawField      (twoWay：无转换，直接同步)
//                ←→  upperField    (twoWayUIMap：接收时转大写)
//                ←→  trimField     (twoWayUIMap：接收时 trim 空格)
//                 →  modelLabel    (receive：显示 model 真实存储值)
//
//  验证点：
//  1. 在 rawField 输入 "hello"  → upperField 显示 "HELLO"，trimField 显示 "hello"
//  2. 点击按钮写入 "  hello world  " → trimField 显示 "hello world"，rawField 显示原始值
//  3. 在 upperField 输入 "abc" → 广播原始 "abc"，model 存 "abc"，rawField 显示 "abc"
//     （说明：twoWayMap 广播时不经过 convertBlock，模型存的是原始值）
//

#import "ConvertDemoViewController.h"
#import "ConvertDemoView.h"
#import "ConvertDemoModel.h"
#import "JHBinderKit.h"

@interface ConvertDemoViewController ()

@property (nonatomic, strong) ConvertDemoView  *demoView;
@property (nonatomic, strong) ConvertDemoModel *model;
@property (nonatomic, strong) NSMutableArray   *bindings;

@end

@implementation ConvertDemoViewController

- (void)loadView {
    self.view = [[ConvertDemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demoView = (ConvertDemoView *)self.view;
    self.model    = [[ConvertDemoModel alloc] init];
    self.bindings = [NSMutableArray array];
    [self p_bindData];
    [self p_setupActions];
}

- (void)p_bindData {
    JHBinder
        // 节点 A：twoWay，与 model 直接双向绑定，无转换
        .twoWay(self.model, @"text")
        .twoWayUI(self.demoView.rawField, @"text", UIControlEventEditingChanged)

        // 节点 B：twoWayUIMap，接收到广播时 convertBlock 把值转大写再显示
        //         广播自身变化时，传递原始用户输入（不经过 convertBlock）
        .twoWayUIMap(self.demoView.upperField, @"text", UIControlEventEditingChanged,
                    ^id(NSString *value) {
                        return value.uppercaseString;
                    })

        // 节点 C：twoWayUIMap，接收到广播时 convertBlock 去除首尾空格
        .twoWayUIMap(self.demoView.trimField, @"text", UIControlEventEditingChanged,
                    ^id(NSString *value) {
                        return [value stringByTrimmingCharactersInSet:
                                NSCharacterSet.whitespaceCharacterSet];
                    })

        // 节点 D：receive，只接收，显示 model.text 真实存储值（无转换）
        .receive(self.demoView.modelLabel, @"text")

        .store(self.bindings);
}

- (void)p_setupActions {
    [self.demoView.setValueBtn addTarget:self
                                  action:@selector(p_onSetValueTapped)
                        forControlEvents:UIControlEventTouchUpInside];
}

- (void)p_onSetValueTapped {
    // 代码写入含首尾空格的值，验证：
    //   trimField 的 convertBlock 会自动去掉空格
    //   rawField 和 modelLabel 显示原始值（含空格，但 rawField 是 UITextField 看不到空格）
    self.model.text = @"  hello world  ";
}

@end
