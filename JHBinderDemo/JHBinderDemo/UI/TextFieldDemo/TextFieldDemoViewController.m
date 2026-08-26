//
//  TextFieldDemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  演示：
//    - 两个 UITextField 双向同步（twoWayUI）
//    - filter：超过 20 字的输入自动截断
//    - receiveMap：转大写值转换
//    - observe block：字数实时统计
//

#import "TextFieldDemoViewController.h"
#import "TextFieldDemoView.h"
#import "TextFieldDemoModel.h"
#import "JHBinderKit.h"

@interface TextFieldDemoViewController ()

@property (nonatomic, strong) TextFieldDemoView  *demoView;
@property (nonatomic, strong) TextFieldDemoModel *model;
@property (nonatomic, strong) NSMutableArray     *bindings;

@end

@implementation TextFieldDemoViewController

- (void)loadView {
    self.view = [[TextFieldDemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demoView = (TextFieldDemoView *)self.view;
    self.model    = [[TextFieldDemoModel alloc] init];
    self.bindings = [NSMutableArray array];
    [self p_bindData];
}

- (void)p_bindData {
    __weak __typeof(self) weak = self;

    // 单条绑定链覆盖所有节点：
    //   model.text（双向 KVO）
    //     ↔ textField1（UIControlEventEditingChanged）
    //     ↔ textField2（UIControlEventEditingChanged）
    //     → labelNormal（原始文本）
    //     → labelUpper（转大写，convertBlock）
    //     filter：超过 20 字不更新
    //     observe：实时更新字数统计
    JHBinder
        .twoWay(self.model, @"text")
        .twoWayUI(self.demoView.textField1, @"text", UIControlEventEditingChanged)
        .twoWayUI(self.demoView.textField2, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.labelNormal, @"text")
        .receiveMap(self.demoView.labelUpper, @"text", ^id(NSString *text) {
            return text.uppercaseString;
        })
        .filter(^BOOL(id __unused old, id new) {
            // 超过 20 字截断，返回 NO 则本次广播被丢弃
            NSString *text = (NSString *)new;
            return text.length <= 20;
        })
        .observe(@"textfield.text.changed", ^(id value) {
            NSString *text = (NSString *)value ?: @"";
            weak.demoView.counterLabel.text =
                [NSString stringWithFormat:@"当前字数：%lu / 20", (unsigned long)text.length];
        })
        .store(self.bindings);
}

@end
