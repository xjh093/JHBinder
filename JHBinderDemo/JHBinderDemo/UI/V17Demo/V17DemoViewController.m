//
//  V17DemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//
//  演示 v1.7 八个新特性：
//
//  ① interval + takeUntil  — 定时器源 + 信号触发自动解绑
//  ② pluck                 — KVC 提取嵌套属性
//  ③ bufferCount(3)        — 攒够 N 个值后打包广播
//  ④ bufferTime(2s)        — 时间窗口打包广播
//  ⑤ timeout(4s)           — 超时降级发出 fallback
//  ⑥ sample(1s)            — 高频源降频采样推送
//  ⑦ combine               — combineLatest 链式实例版
//  ⑧ elementAt(3)          — 只对第 N 次广播响应
//

#import "V17DemoViewController.h"
#import "V17DemoView.h"
#import "V17DemoModel.h"
#import "JHBinderKit.h"

@interface V17DemoViewController ()
@property (nonatomic, strong) V17DemoView  *demoView;
@property (nonatomic, strong) V17DemoModel *model;
@property (nonatomic, strong) NSMutableArray *bindings;
/// bufferCount 已入队计数（用于 hint label 显示，不走绑定）
@property (nonatomic, assign) NSInteger bufferQueueCount;
/// rapidCounter 快速递增次数
@property (nonatomic, assign) NSInteger rawCounter;
/// stopSignal 触发 binder（为 takeUntil 而建）
@property (nonatomic, strong) JHBinder *stopSignalBinder;
@end

@implementation V17DemoViewController

- (void)loadView {
    self.view = [[V17DemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title    = @"v1.7 新特性";
    self.demoView = (V17DemoView *)self.view;
    self.model    = [[V17DemoModel alloc] init];
    self.bindings = [NSMutableArray array];
    [self p_bindData];
    [self p_setupActions];
}

// MARK: - 数据绑定

- (void)p_bindData {
    __weak typeof(self) weak = self;

    // ── ① interval + takeUntil ───────────────────────────────────
    // interval(1s) 每秒广播一次 tick（NSNumber 0, 1, 2…）。
    // 建立一个独立的 "stopSignal" 链：当 model.stopSignal 非 nil 时广播。
    // takeUntil 监听 stopSignalBinder；stopSignal 广播时 ticker 链自动 removeAllNodes。
    _stopSignalBinder = JHBinder
        .listen(self.model, @"stopSignal")
        .filter(^BOOL(id __unused old, id v){ return v && v != [NSNull null]; });
    // _stopSignalBinder 由 strong property 持有，无需 store；dealloc 时随 VC 一起释放

    JHBinder
        .interval(1.0)
        .takeUntil(_stopSignalBinder)
        .observe(@"v17.ticker", ^(id tick) {
            weak.demoView.tickerLabel.text = [NSString stringWithFormat:@"⏱ Tick：%@", tick];
        })
        .store(self.bindings);

    // ── ② pluck ──────────────────────────────────────────────────
    // model.apiResponse 由按钮动作设置为嵌套字典。
    // pluck(@"user.name") 利用 KVC 提取 name 字段。
    JHBinder
        .listen(self.model, @"apiResponse")
        .pluck(@"user.name")
        .receive(self.demoView.pluckResultLabel, @"text")
        .store(self.bindings);

    // ── ③ bufferCount(3) ─────────────────────────────────────────
    // model.bufferEventValue 每次递增一个整数。
    // bufferCount(3) 积累 3 个后打包为 NSArray，一次性广播给 label。
    JHBinder
        .listen(self.model, @"bufferEventValue")
        .filter(^BOOL(id __unused old, id v){ return v && v != [NSNull null]; })
        .bufferCount(3)
        .observe(@"v17.bufCount", ^(id batch) {
            NSArray *arr = batch;
            NSString *inline_ = [arr componentsJoinedByString:@", "];
            weak.demoView.bufferCountLabel.text =
                [NSString stringWithFormat:@"批次结果(%lu 个)：[%@]",
                 (unsigned long)arr.count, inline_];
            weak.bufferQueueCount = 0;
            weak.demoView.bufferCountHintLabel.text = @"已入队：0/3（已 flush）";
        })
        .store(self.bindings);

    // ── ④ bufferTime(2s) ─────────────────────────────────────────
    // 监听文本框的编辑内容（UIControlEventEditingChanged）。
    // bufferTime(2s) 在 2 秒内积累所有输入，然后打包广播。
    JHBinder
        .twoWay(self.model, @"rapidText")
        .listenUI(self.demoView.bufferTimeField, @"text", UIControlEventEditingChanged)
        .bufferTime(2.0)
        .observe(@"v17.bufTime", ^(id batch) {
            NSArray *arr = batch;
            NSString *inline_ = [arr componentsJoinedByString:@", "];
            weak.demoView.bufferTimeLabel.text =
                [NSString stringWithFormat:@"批次(%lu 条)：[%@]",
                 (unsigned long)arr.count, inline_];
        })
        .store(self.bindings);

    // ── ⑤ timeout(4s) ────────────────────────────────────────────
    // 监听 model.activeText；每次点"重置计时"按钮更新该属性。
    // 4 秒内无新广播 → 自动向 label 发出 fallback 文字。
    // startWith 给初始状态文字并同时启动 timeout 第一轮计时。
    JHBinder
        .listen(self.model, @"activeText")
        .timeout(4.0, @"⏰ 4 秒无操作，超时！")
        .receive(self.demoView.timeoutStatusLabel, @"text")
        .startWith(@"等待用户操作（4s 超时）…")
        .store(self.bindings);

    // ── ⑥ sample(1s) ─────────────────────────────────────────────
    // model.rapidCounter 通过快速点击按钮快速递增。
    // sample(1s) 每隔 1 秒将 lastEffectiveValue 推送一次到 sampleLabel。
    // sampleRawLabel 直接同步（无 sample），体现频率对比。
    JHBinder
        .listen(self.model, @"rapidCounter")
        .filter(^BOOL(id __unused old, id v){ return v && v != [NSNull null]; })
        .receive(self.demoView.sampleRawLabel, @"text")
        .nodeMap(^id(id v){ return [NSString stringWithFormat:@"raw: %@", v]; })
        .store(self.bindings);

    JHBinder
        .listen(self.model, @"rapidCounter")
        .filter(^BOOL(id __unused old, id v){ return v && v != [NSNull null]; })
        .sample(1.0)
        .receive(self.demoView.sampleLabel, @"text")
        .nodeMap(^id(id v){ return [NSString stringWithFormat:@"sample: %@", v]; })
        .store(self.bindings);

    // ── ⑦ combine ────────────────────────────────────────────────
    // binderA / binderB 分别监听两个文本框。
    // combine(binderB, block) 等价于 combineLatest:@[binderA, binderB]；
    // 两路都有值后才开始广播合并结果。
    // combine 返回的 combined binder 内部已强持有 binderA / binderB，
    // 无需单独 store binderA / binderB。
    JHBinder *binderA = JHBinder
        .twoWay(self.model, @"combineA")
        .listenUI(self.demoView.combineFieldA, @"text", UIControlEventEditingChanged);

    JHBinder *binderB = JHBinder
        .twoWay(self.model, @"combineB")
        .listenUI(self.demoView.combineFieldB, @"text", UIControlEventEditingChanged);

    binderA
        .combine(binderB, ^id(NSArray *vs) {
            return [NSString stringWithFormat:@"%@ + %@ = %@%@", vs[0], vs[1], vs[0], vs[1]];
        })
        .receive(self.demoView.combineResultLabel, @"text")
        .store(self.bindings);

    // ── ⑧ elementAt(3) ───────────────────────────────────────────
    // 每次点"点我"按钮 tapCount 递增。
    // elementAt(3) = skip(2) + take(1)；前 2 次跳过，第 3 次广播后自动解绑。
    JHBinder
        .listen(self.model, @"tapCount")
        .filter(^BOOL(id __unused old, id v){ return v && v != [NSNull null]; })
        .elementAt(3)
        .observe(@"v17.elem", ^(id v) {
            weak.demoView.elementAtLabel.text =
                [NSString stringWithFormat:@"🎯 第 3 次触发！值：%@（已解绑）", v];
            [weak.demoView.elementAtButton setEnabled:NO];
        })
        .store(self.bindings);
}

// MARK: - 按钮动作

- (void)p_setupActions {
    // ① 停止 ticker
    [self.demoView.stopButton addTarget:self
                                 action:@selector(p_onStop)
                       forControlEvents:UIControlEventTouchUpInside];
    // ② pluck 请求
    [self.demoView.pluckRequestButton addTarget:self
                                         action:@selector(p_onPluckRequest)
                               forControlEvents:UIControlEventTouchUpInside];
    // ③ bufferCount 入队
    [self.demoView.bufferCountButton addTarget:self
                                        action:@selector(p_onBufferCountEnqueue)
                              forControlEvents:UIControlEventTouchUpInside];
    // ⑤ timeout 重置
    [self.demoView.timeoutResetButton addTarget:self
                                         action:@selector(p_onTimeoutReset)
                               forControlEvents:UIControlEventTouchUpInside];
    // ⑥ 快速递增
    [self.demoView.rapidButton addTarget:self
                                  action:@selector(p_onRapidTap)
                        forControlEvents:UIControlEventTouchUpInside];
    // ⑧ elementAt
    [self.demoView.elementAtButton addTarget:self
                                      action:@selector(p_onElementAtTap)
                            forControlEvents:UIControlEventTouchUpInside];
}

// MARK: - Action 实现

- (void)p_onStop {
    // 设置 stopSignal → stopSignalBinder 广播 → takeUntil 触发 → ticker 链 removeAllNodes
    self.model.stopSignal = @YES;
    [self.demoView.stopButton setEnabled:NO];
    [self.demoView.stopButton setTitle:@"已停止" forState:UIControlStateNormal];
}

- (void)p_onPluckRequest {
    // 模拟网络返回一个嵌套字典
    self.model.apiResponse = @{
        @"code": @200,
        @"user": @{ @"name": @"Alice", @"age": @28 }
    };
}

- (void)p_onBufferCountEnqueue {
    static NSInteger _val = 0;
    _val++;
    self.bufferQueueCount++;
    self.model.bufferEventValue = @(_val);
    self.demoView.bufferCountHintLabel.text =
        [NSString stringWithFormat:@"已入队：%ld/3", (long)self.bufferQueueCount];
}

- (void)p_onTimeoutReset {
    NSDateFormatter *fmt = [NSDateFormatter new];
    fmt.dateFormat = @"HH:mm:ss";
    self.model.activeText = [NSString stringWithFormat:@"✅ %@ 已重置，重新计时",
                              [fmt stringFromDate:[NSDate date]]];
}

- (void)p_onRapidTap {
    self.rawCounter++;
    self.model.rapidCounter = @(self.rawCounter);
}

- (void)p_onElementAtTap {
    NSInteger _tapN = self.model.tapCount.intValue;
    _tapN++;
    self.model.tapCount = @(_tapN);
    // 在标签上显示当前是第几次（仅前两次显示，第三次由 elementAt observe 回调覆盖）
    if (_tapN < 3) {
        self.demoView.elementAtLabel.text =
            [NSString stringWithFormat:@"第 %ld 次（等待第 3 次）…", (long)_tapN];
    }
}

// MARK: - 生命周期

- (void)dealloc {
    [self.bindings removeAllObjects];
}

@end
