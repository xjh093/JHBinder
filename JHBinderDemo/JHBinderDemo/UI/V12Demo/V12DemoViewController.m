//
//  V12DemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/26/26.
//
//  演示 v1.2 六个新特性：
//    ① fire()       — 绑定建立时立即同步模型当前值到 UI
//    ② debounce(t)  — 停止触发 t 秒后才广播（含 log 输出至控制台）
//    ③ delay(t)     — 每次触发延迟 t 秒后广播，不取消前次
//    ④ distinct()   — UIControl 重复值不广播
//    ⑤ once()       — 首次广播后自动解绑，UI 冻结
//    ⑥ log(label)   — 广播时打印日志（见 Xcode 控制台，用于 ② 的 debounce 链）
//

#import "V12DemoViewController.h"
#import "V12DemoView.h"
#import "V12DemoModel.h"
#import "JHBinderKit.h"

@interface V12DemoViewController ()

@property (nonatomic, strong) V12DemoView  *demoView;
@property (nonatomic, strong) V12DemoModel *model;
@property (nonatomic, strong) NSMutableArray *bindings;

@property (nonatomic, assign) NSUInteger debounceCount;
@property (nonatomic, assign) NSUInteger distinctCount;

@end

@implementation V12DemoViewController

- (void)loadView {
    self.view = [[V12DemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"v1.2 新特性";
    self.demoView = (V12DemoView *)self.view;
    self.model    = [[V12DemoModel alloc] init];
    self.bindings = [NSMutableArray array];

    // fire 演示：预设模型初始值，绑定建立后由 fire() 立即同步到 UI
    self.model.fireText = @"Hello JHBinder v1.2 🎉";

    [self p_bindData];
}

- (void)p_bindData {
    __weak typeof(self) weak = self;

    // ── ① fire() ─────────────────────────────────────────────────
    // model.fireText 已有初始值，fire() 让 fireLabel 无需等待用户操作即可显示
    JHBinder
        .twoWay(self.model, @"fireText")
        .receive(self.demoView.fireLabel, @"text")
        .fire()
        .store(self.bindings);

    // ── ② debounce(0.3) + log(@"debounce") ───────────────────────
    // 用户输入时 debounceResultLabel 不立即更新；
    // 停止输入 0.3s 后才广播，count 才递增；
    // 每次实际广播在 Xcode 控制台可见 [JHBinder:debounce] 日志
    JHBinder
        .twoWay(self.model, @"debounceText")
        .twoWayUI(self.demoView.debounceField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.debounceResultLabel, @"text")
        .debounce(0.3)
        .log(@"debounce")
        .observe(@"v12.debounce.count", ^(id __unused v) {
            weak.debounceCount++;
            weak.demoView.debounceCountLabel.text =
                [NSString stringWithFormat:@"广播次数：%lu", (unsigned long)weak.debounceCount];
        })
        .store(self.bindings);

    // ── ③ delay(0.5) ─────────────────────────────────────────────
    // 每次输入都会在 0.5s 后各自触发一次更新；
    // 快速连续输入时，每次都延迟 0.5s，可能出现"后来的先到"现象
    JHBinder
        .twoWay(self.model, @"delayText")
        .twoWayUI(self.demoView.delayField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.delayResultLabel, @"text")
        .delay(0.5)
        .store(self.bindings);

    // ── ④ distinct() ─────────────────────────────────────────────
    // 使用 EditingDidEndOnExit（按键盘 Enter 键触发），这样同一个值可以连续发送两次。
    // 输入 "abc" 按 Enter → 广播（count+1）；再次按 Enter 不改文字 → 相同值 → 拦截（count 不变）
    // 注意：EditingChanged 每次击键值都不同，无法演示 distinct
    JHBinder
        .twoWay(self.model, @"distinctText")
        .twoWayUI(self.demoView.distinctField, @"text", UIControlEventEditingDidEndOnExit)
        .receive(self.demoView.distinctResultLabel, @"text")
        .distinct()
        .observe(@"v12.distinct.count", ^(id __unused v) {
            weak.distinctCount++;
            weak.demoView.distinctCountLabel.text =
                [NSString stringWithFormat:@"广播次数：%lu", (unsigned long)weak.distinctCount];
        })
        .store(self.bindings);

    // ── ⑤ once() ─────────────────────────────────────────────────
    // 首次输入后 onceResultLabel 更新并冻结；
    // 之后无论输入什么，label 都不再变化（KVO + Target-Action 已解除）
    JHBinder
        .twoWay(self.model, @"onceText")
        .twoWayUI(self.demoView.onceField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.onceResultLabel, @"text")
        .once()
        .store(self.bindings);
}

@end
