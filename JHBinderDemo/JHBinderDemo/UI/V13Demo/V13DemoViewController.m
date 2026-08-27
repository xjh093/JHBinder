//
//  V13DemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/26/26.
//
//  演示 v1.3 两个新特性：
//
//  ① nodeMap + nodeFilter — 节点级独立 map / filter（分流显示）
//     同一 filterText 属性广播给两个 label：
//       - shortLabel：长度 < 5 才接收，显示 "💬 xxx"
//       - longLabel ：长度 ≥ 5 才接收，显示 "📝 xxx"
//     验证点：输入 "hi" → 只有 shortLabel 更新；
//             输入 "hello world" → 只有 longLabel 更新。
//
//  ② combineLatest — 多源合并
//     firstName + lastName → fullNameLabel 实时合并
//     firstName + lastName（均非空）→ submitButton.enabled
//     验证点：只填一个字段时 fullName 不变、按钮不 enabled；
//             两个都填写后立即合并、按钮 enabled。
//

#import "V13DemoViewController.h"
#import "V13DemoView.h"
#import "V13DemoModel.h"
#import "JHBinderKit.h"

@interface V13DemoViewController ()

@property (nonatomic, strong) V13DemoView  *demoView;
@property (nonatomic, strong) V13DemoModel *model;
@property (nonatomic, strong) NSMutableArray *bindings;

@end

@implementation V13DemoViewController

- (void)loadView {
    self.view = [[V13DemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"v1.3 新特性";
    self.demoView = (V13DemoView *)self.view;
    self.model    = [[V13DemoModel alloc] init];
    self.bindings = [NSMutableArray array];
    [self p_bindData];
    [self p_setupActions];
}

- (void)p_bindData {
    // ── ① nodeMap + nodeFilter（分流） ────────────────────────────
    //
    // 一条链，两个 receive 节点，各自独立 map + filter：
    //   shortLabel：nodeFilter 过滤掉长度 ≥ 5 的值，只显示短文本
    //   longLabel ：nodeFilter 过滤掉长度 <  5 的值，只显示长文本
    //
    // 关键：节点级 filter 返回 NO 时只跳过该节点，另一个节点照常接收。
    //       （若用链级 filter，则两个节点都会被丢弃）
    JHBinder
        .twoWay(self.model, @"filterText")
        .twoWayUI(self.demoView.filterField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.shortLabel, @"text")
            .nodeMap(^id(NSString *v){
                return [NSString stringWithFormat:@"💬 %@", v ?: @""];
            })
            .nodeFilter(^BOOL(NSString *v){
                return v.length < 5;
            })
        .receive(self.demoView.longLabel, @"text")
            .nodeMap(^id(NSString *v){
                return [NSString stringWithFormat:@"📝 %@", v ?: @""];
            })
            .nodeFilter(^BOOL(NSString *v){
                return v.length >= 5;
            })
        .store(self.bindings);

    // ── ② combineLatest（姓名合并 + 按钮联动） ────────────────────
    //
    // 链 A：firstName 输入框 → 模型
    // 链 B：lastName  输入框 → 模型
    // combineLatest：两者都至少发射一次后，合并显示到 fullNameLabel
    //
    // 额外演示：另一个 combineLatest 驱动 submitButton.enabled
    //           两个输入框均非空时才 enabled（两个独立 combine，各自存储）

    JHBinder *binderFirst = JHBinder
        .twoWay(self.model, @"firstName")
        .twoWayUI(self.demoView.firstNameField, @"text", UIControlEventEditingChanged);

    JHBinder *binderLast = JHBinder
        .twoWay(self.model, @"lastName")
        .twoWayUI(self.demoView.lastNameField, @"text", UIControlEventEditingChanged);

    // 合并显示姓名（lastName + firstName，中文习惯顺序）
    [JHBinder combineLatest:@[binderFirst, binderLast] combineMap:^id(NSArray *v) {
        NSString *first = v[0] ?: @"";
        NSString *last  = v[1] ?: @"";
        if (first.length == 0 && last.length == 0) return @"（两个字段都为空）";
        return [NSString stringWithFormat:@"%@%@", last, first];
    }]
    .receive(self.demoView.fullNameLabel, @"text")
    .store(self.bindings);

    // 合并控制按钮 enabled（两个字段均非空才可点击）
    [JHBinder combineLatest:@[binderFirst, binderLast] combineMap:^id(NSArray *v) {
        NSString *first = v[0];
        NSString *last  = v[1];
        BOOL enabled = first.length > 0 && last.length > 0;
        return @(enabled);
    }]
    .receive(self.demoView.submitButton, @"enabled")
    .store(self.bindings);

    // binderFirst / binderLast 由两个 combineLatest binder 内部持有
    // 无需单独 store，但若需要它们各自的 receive 节点也可单独 store
}

- (void)p_setupActions {
    [self.demoView.submitButton addTarget:self
                                   action:@selector(p_onSubmit)
                         forControlEvents:UIControlEventTouchUpInside];
}

- (void)p_onSubmit {
    NSString *name = [NSString stringWithFormat:@"%@%@",
                      self.model.lastName ?: @"",
                      self.model.firstName ?: @""];
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"提交成功"
                         message:[NSString stringWithFormat:@"姓名：%@", name]
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
