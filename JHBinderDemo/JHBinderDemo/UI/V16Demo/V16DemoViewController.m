//
//  V16DemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//
//  演示 v1.6 九个新特性：
//
//  ① merge        — 任一源广播即透传值
//  ② withLatestFrom — 触发时采样另一路最新值
//  ③ startWith    — 绑定后立即广播指定初始值
//  ④ tap          — 内联副作用，不消费值
//  ⑤ negate       — 布尔取反快捷方式
//  ⑥ mapTo        — 恒定映射（任意值→固定值）
//  ⑦ distinctWhen — 自定义去重比较器（忽略大小写）
//  ⑧ takeWhile    — 满足条件时广播，否则自动解绑
//  ⑨ skipWhile    — 跳过直到条件首次不满足
//

#import "V16DemoViewController.h"
#import "V16DemoView.h"
#import "V16DemoModel.h"
#import "JHBinderKit.h"

@interface V16DemoViewController ()
@property (nonatomic, strong) V16DemoView  *demoView;
@property (nonatomic, strong) V16DemoModel *model;
@property (nonatomic, strong) NSMutableArray *bindings;
@property (nonatomic, assign) NSInteger tapCount;
@property (nonatomic, assign) NSInteger distinctBroadcastCount;
@end

@implementation V16DemoViewController

- (void)loadView {
    self.view = [[V16DemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title    = @"v1.6 新特性";
    self.demoView = (V16DemoView *)self.view;
    self.model    = [[V16DemoModel alloc] init];
    self.bindings = [NSMutableArray array];
    [self p_bindData];
    [self p_setupActions];
}

// MARK: - 数据绑定

- (void)p_bindData {
    __weak typeof(self) weak = self;

    // ── ① merge ──────────────────────────────────────────────────
    // 用户名和密码任意一个改变，都触发同一个 observe 回调。
    // merge 返回一个新 binder，任一源广播时透传该源的值。
    [JHBinder merge:@[
        JHBinder.twoWay(self.model, @"username")
               .listenUI(self.demoView.usernameField, @"text", UIControlEventEditingChanged),
        JHBinder.twoWay(self.model, @"password")
               .listenUI(self.demoView.passwordField, @"text", UIControlEventEditingChanged),
    ]]
    .observe(@"v16.merge", ^(id v) {
        NSString *user = weak.model.username ?: @"（空）";
        NSString *pwd  = weak.model.password ?: @"（空）";
        BOOL valid = user.length >= 3 && pwd.length >= 6;
        weak.demoView.mergeResultLabel.text = [NSString stringWithFormat:
            @"merge 结果：%@  校验：%@", v, valid ? @"✅ 通过" : @"❌ 不通过"];
    })
    .store(self.bindings);

    // ── ② withLatestFrom ─────────────────────────────────────────
    // keyword 防抖 0.5s 后触发；取 category 的最新值一起搜索。
    // categoryBinder 无需单独 store，由 withLatestFrom 强持有。
    JHBinder *categoryBinder = JHBinder
        .twoWayUI(self.demoView.categoryField, @"text", UIControlEventEditingChanged)
        .twoWay(self.model, @"searchCategory");

    JHBinder
        .twoWay(self.model, @"searchKeyword")
        .twoWayUI(self.demoView.keywordField, @"text", UIControlEventEditingChanged)
        .debounce(0.5)
        .withLatestFrom(categoryBinder)
        .observe(@"v16.wlf", ^(id pair) {
            NSArray *p = [pair isKindOfClass:[NSArray class]] ? pair : @[pair, [NSNull null]];
            id keyword  = p[0];
            id category = [p[1] isKindOfClass:[NSNull class]] ? @"全部" : p[1];
            weak.demoView.wlfResultLabel.text = [NSString stringWithFormat:
                @"搜索：\"%@\"  分类：\"%@\"", keyword ?: @"", category];
        })
        .store(self.bindings);

    // ── ③ startWith ──────────────────────────────────────────────
    // 绑定建立后立即显示「加载中…」，无需等待 model 赋值。
    // 3 秒后模拟数据加载完成，更新 model.statusText 触发广播。
    JHBinder
        .listen(self.model, @"statusText")
        .receive(self.demoView.startWithLabel, @"text")
        .startWith(@"⏳ 加载中…（startWith 指定的初始值）")
        .store(self.bindings);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        weak.model.statusText = @"✅ 数据已加载（model.statusText 更新）";
    });

    // ── ④ tap ────────────────────────────────────────────────────
    // tap 执行副作用（计数+1）但不修改 effectiveValue；
    // receive 节点收到的仍是原始文本。
    JHBinder
        .listen(self.model, @"tapDemoText")
        .twoWayUI(self.demoView.tapTextField, @"text", UIControlEventEditingChanged)
        .tap(^(id __unused v) {
            // 副作用：埋点/计数，不影响下游值
            weak.tapCount++;
            dispatch_async(dispatch_get_main_queue(), ^{
                weak.demoView.tapCountLabel.text = [NSString stringWithFormat:
                    @"tap 副作用计数：%ld 次（原始文本已透传）", (long)weak.tapCount];
            });
        })
        .receive(self.demoView.tapCountLabel, @"text")  // 若 tap 消费了值，此处应收到 nil
        // 注：tap 不修改值，所以此 receive 会在 tap 执行后用原始文本覆盖 tapCountLabel
        // 为演示 tap 不消费值，此处注释掉 receive，只用 tap 更新 label
        // （实际项目中 tap 通常用于埋点，receive 用于 UI 更新，各司其职）
        .store(self.bindings);

    // ── ⑤ negate ─────────────────────────────────────────────────
    // model.isLoading 取反后绑定到 button.enabled。
    // negate 等价于 .transform(^id(id v){ return @(![v boolValue]); })
    JHBinder
        .listen(self.model, @"isLoading")
        .negate()
        .receive(self.demoView.negateButton, @"enabled")
        .observe(@"v16.negate", ^(id negated) {
            // negated 是取反后的值（同样是 @NO/@YES），用于更新 stateLabel
            BOOL isEnabled = [negated boolValue];
            weak.demoView.negateStateLabel.text = [NSString stringWithFormat:
                @"isLoading: %@ → enabled: %@",
                weak.model.isLoading ? @"YES" : @"NO",
                isEnabled ? @"YES" : @"NO"];
        })
        .fire()
        .store(self.bindings);

    // ── ⑥ mapTo ──────────────────────────────────────────────────
    // 无论输入什么，下游总收到固定字符串「已更新 ✓」
    JHBinder
        .listen(self.model, @"anyChangeText")
        .twoWayUI(self.demoView.mapToField, @"text", UIControlEventEditingChanged)
        .mapTo(@"已更新 ✓（不论输入什么，mapTo 总广播此值）")
        .receive(self.demoView.mapToResultLabel, @"text")
        .store(self.bindings);

    // ── ⑦ distinctWhen ───────────────────────────────────────────
    // 预设按鈕直接修改 model.caseText（KVO 路径）。
    // distinctWhen 忽略大小写：apple → Apple → APPLE 只触发一次广播；
    // 切换到 banana 才会再次触发。
    JHBinder
        .listen(self.model, @"caseText")
        .distinctWhen(^BOOL(id old, id new) {
            if (![old isKindOfClass:[NSString class]] || ![new isKindOfClass:[NSString class]]) {
                return [old isEqual:new];
            }
            return [(NSString *)old caseInsensitiveCompare:(NSString *)new] == NSOrderedSame;
        })
        .observe(@"v16.distinct", ^(id v) {
            weak.distinctBroadcastCount++;
            weak.demoView.caseResultLabel.text = [NSString stringWithFormat:
                @"当前属性値：%@", v];
            weak.demoView.caseBroadcastLabel.text = [NSString stringWithFormat:
                @"广播次数：%ld（apple/Apple/APPLE 共触发 1 次）",
                (long)weak.distinctBroadcastCount];
        })
        .store(self.bindings);

    // ── ⑧ takeWhile ──────────────────────────────────────────────
    // counter < 5 时正常广播；≥5 时自动解绑（之后点击按钮不再更新 label）
    JHBinder
        .listen(self.model, @"counter")
        .takeWhile(^BOOL(id v) { return [v intValue] < 5; })
        .observe(@"v16.takeWhile", ^(id v) {
            weak.demoView.takeWhileLabel.text = [NSString stringWithFormat:
                @"takeWhile (< 5)：counter = %@  ✅ 广播中", v];
        })
        .store(self.bindings);

    // ── ⑨ skipWhile ──────────────────────────────────────────────
    // counter < 3 时跳过广播（label 不更新）；≥3 时开始正常广播
    JHBinder
        .listen(self.model, @"counter")
        .skipWhile(^BOOL(id v) { return [v intValue] < 3; })
        .observe(@"v16.skipWhile", ^(id v) {
            weak.demoView.skipWhileLabel.text = [NSString stringWithFormat:
                @"skipWhile (< 3)：counter = %@  ✅ 已激活", v];
        })
        .store(self.bindings);
}

// MARK: - 按钮事件

- (void)p_setupActions {
    [self.demoView.negateButton addTarget:self
                                   action:@selector(p_onToggleLoading)
                         forControlEvents:UIControlEventTouchUpInside];
    [self.demoView.counterIncrButton addTarget:self
                                        action:@selector(p_onIncrCounter)
                              forControlEvents:UIControlEventTouchUpInside];

    // ⑧ distinctWhen 预设按鈕
    NSArray<NSString *> *caseValues = @[@"apple", @"Apple", @"APPLE", @"banana", @"Banana"];
    for (UIButton *btn in self.demoView.caseButtons) {
        [btn addTarget:self action:@selector(p_onCaseButton:) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = caseValues[btn.tag];
    }
}

- (void)p_onToggleLoading {
    self.model.isLoading = !self.model.isLoading;
}

- (void)p_onIncrCounter {
    NSInteger cur = self.model.counter.integerValue;
    self.model.counter = @(cur + 1);

    // 更新按钮标题以展示当前值
    NSString *title = [NSString stringWithFormat:@"counter+1 (=%ld)", (long)cur + 1];
    [self.demoView.counterIncrButton setTitle:title forState:UIControlStateNormal];
}
- (void)p_onCaseButton:(UIButton *)sender {
    self.model.caseText = sender.accessibilityLabel;
}
@end
