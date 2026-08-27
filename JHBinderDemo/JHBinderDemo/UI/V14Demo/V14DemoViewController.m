//
//  V14DemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//
//  演示 v1.4 四个新特性：
//
//  ① defaultValue — 广播值为 nil/NSNull 时替换为默认值
//     验证：点「重置」→ model.defaultText = nil → label 显示「（未填写）」
//
//  ② skip(2) — 跳过前 2 次广播
//     验证：前两次输入 label 不动，第三次才开始同步
//
//  ③ take(3) — 只广播 3 次后自动解绑
//     验证：第 4 次输入起 label 不再变化
//
//  ④ throttle(1.0) — 窗口期 1 秒内只允许第一次广播通过（前沿）
//     验证：快速连续输入，label 每秒只更新一次
//
//  ⑤ throttleTrailing(1.0) — 前沿立即发，窗口结束时补发最后一个值
//     验证：快速输入 t=0 就广播，1s 后再广播一次最终结果
//
//  ⑥ throttleTrailingOnly(1.0) — 窗口结束时发最后一个值（后沿）
//     验证：快速输入全部压制，1s 后一次性广播最终值
//

#import "V14DemoViewController.h"
#import "V14DemoView.h"
#import "V14DemoModel.h"
#import "JHBinderKit.h"

@interface V14DemoViewController ()
@property (nonatomic, strong) V14DemoView  *demoView;
@property (nonatomic, strong) V14DemoModel *model;
@property (nonatomic, strong) NSMutableArray *bindings;

@property (nonatomic, assign) NSUInteger skipFiredCount;
@property (nonatomic, assign) NSUInteger takeRemaining;
@property (nonatomic, assign) NSUInteger throttleCount;
@property (nonatomic, assign) NSUInteger throttleTrailingCount;
@property (nonatomic, assign) NSUInteger throttleTrailingOnlyCount;
@end

@implementation V14DemoViewController

- (void)loadView {
    self.view = [[V14DemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title    = @"v1.4 新特性";
    self.demoView = (V14DemoView *)self.view;
    self.model    = [[V14DemoModel alloc] init];
    self.bindings = [NSMutableArray array];
    self.takeRemaining = 3;
    [self p_bindData];
    [self p_setupActions];
}

- (void)p_bindData {
    __weak typeof(self) weak = self;

    // ── ① defaultValue ───────────────────────────────────────────
    // model.defaultText 初始为 nil，配合 fire() 让 label 立即显示默认文本。
    // 用户输入后 label 同步输入内容；点「重置」令 model = nil → 再次显示默认文本。
    JHBinder
        .twoWay(self.model, @"defaultText")
        .twoWayUI(self.demoView.defaultField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.defaultResultLabel, @"text")
        .defaultValue(@"（未填写）")
        .fire()
        .store(self.bindings);

    // ── ② skip(2) ────────────────────────────────────────────────
    // 前 2 次广播被跳过（label 不更新），第 3 次起正常同步。
    // skip 会拦截广播，令 model.skipText 不会被写入，因此无法用第二条 KVO 链计数。
    // 改为直接给 skipField 添加 UIControl action，绕开绑定层独立统计触发次数。
    JHBinder
        .twoWay(self.model, @"skipText")
        .twoWayUI(self.demoView.skipField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.skipResultLabel, @"text")
        .skip(2)
        .store(self.bindings);

    // ── ③ take(3) ────────────────────────────────────────────────
    // 广播 3 次后自动解绑；observe 用于更新剩余次数提示。
    JHBinder
        .twoWay(self.model, @"takeText")
        .twoWayUI(self.demoView.takeField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.takeResultLabel, @"text")
        .take(3)
        .observe(@"v14.take", ^(id __unused v) {
            if (weak.takeRemaining > 0) weak.takeRemaining--;
            NSString *hint = weak.takeRemaining > 0
                ? [NSString stringWithFormat:@"剩余 %lu 次", (unsigned long)weak.takeRemaining]
                : @"已解绑 🔒";
            weak.demoView.takeCountLabel.text = hint;
        })
        .store(self.bindings);

    // ── ④ throttle(1.0) ──────────────────────────────────────────
    // 每秒最多广播一次：第一次输入立即通过，1 秒内后续丢弃，1 秒后再次通过。
    JHBinder
        .twoWay(self.model, @"throttleText")
        .twoWayUI(self.demoView.throttleField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.throttleResultLabel, @"text")
        .throttle(1.0)
        .observe(@"v14.throttle", ^(id __unused v) {
            weak.throttleCount++;
            weak.demoView.throttleCountLabel.text =
                [NSString stringWithFormat:@"广播 %lu 次", (unsigned long)weak.throttleCount];
        })
        .store(self.bindings);
    // ── ⑤ throttleTrailing(1.0) ─────────────────────────────────────────
    // t=0 第一次立即广播（前沿），1s 内后续输入被压制，1s 后补发最后一个值（后沿）。
    JHBinder
        .twoWay(self.model, @"throttleTrailingText")
        .twoWayUI(self.demoView.throttleTrailingField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.throttleTrailingResultLabel, @"text")
        .throttleTrailing(1.0)
        .observe(@"v14.throttleTrailing", ^(id __unused v) {
            weak.throttleTrailingCount++;
            weak.demoView.throttleTrailingCountLabel.text =
                [NSString stringWithFormat:@"广播 %lu 次", (unsigned long)weak.throttleTrailingCount];
        })
        .store(self.bindings);

    // ── ⑥ throttleTrailingOnly(1.0) ───────────────────────────────────────
    // 窗口内所有输入均被压制，1s 结束时一次性广播最后一个值。
    // 与 debounce 区别：debounce 每次输入重置计时器；此处计时器不重置，保证最大延迟为 1s。
    JHBinder
        .twoWay(self.model, @"throttleTrailingOnlyText")
        .twoWayUI(self.demoView.throttleTrailingOnlyField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.throttleTrailingOnlyResultLabel, @"text")
        .throttleTrailingOnly(1.0)
        .observe(@"v14.throttleTrailingOnly", ^(id __unused v) {
            weak.throttleTrailingOnlyCount++;
            weak.demoView.throttleTrailingOnlyCountLabel.text =
                [NSString stringWithFormat:@"广播 %lu 次", (unsigned long)weak.throttleTrailingOnlyCount];
        })
        .store(self.bindings);}

- (void)p_setupActions {
    [self.demoView.resetButton addTarget:self
                                  action:@selector(p_onReset)
                        forControlEvents:UIControlEventTouchUpInside];
    // 直接监听 skipField 的每次键盘输入，独立于绑定层计数
    [self.demoView.skipField addTarget:self
                                action:@selector(p_onSkipFieldChanged)
                      forControlEvents:UIControlEventEditingChanged];
}

- (void)p_onSkipFieldChanged {
    self.skipFiredCount++;
    if (self.skipFiredCount <= 2) {
        self.demoView.skipHintLabel.text =
            [NSString stringWithFormat:@"已跳过 %lu/2", (unsigned long)self.skipFiredCount];
    } else {
        self.demoView.skipHintLabel.text = @"已跳过 2/2，正常广播中";
    }
}

- (void)p_onReset {
    // 清空模型属性 → KVO 触发 → defaultValue 生效 → label 显示默认文本
    self.model.defaultText = nil;
    self.demoView.defaultField.text = @"";
}

@end
