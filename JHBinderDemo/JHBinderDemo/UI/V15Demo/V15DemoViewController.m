//
//  V15DemoViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//
//  演示 v1.5 四个新特性：
//
//  ① transform — 链级值变换（全局大写）
//     验证：输入小写字母 → result label 实时显示大写版本
//
//  ② scan — 累加器（每次按键计数 +1）
//     验证：每次 EditingChanged 广播，scan 返回累加次数，observe 收到次数而非原始字符串
//
//  ③ withPrevious — 双值打包（接收节点收到 @[prevValue, newValue]）
//     验证：result label 显示"从 X 变为 Y"
//
//  ④ biMap — 双向映射（model 存 NSNumber，UI 展示 NSString）
//     验证：+/- 按钮改变 model → UI 自动更新；回车提交 → 字符串转回 NSNumber 写入 model
//

#import "V15DemoViewController.h"
#import "V15DemoView.h"
#import "V15DemoModel.h"
#import "JHBinderKit.h"

@interface V15DemoViewController ()
@property (nonatomic, strong) V15DemoView  *demoView;
@property (nonatomic, strong) V15DemoModel *model;
@property (nonatomic, strong) NSMutableArray *bindings;
@property (nonatomic, strong) NSMutableString *scanHistory;
@end

@implementation V15DemoViewController

- (void)loadView {
    self.view = [[V15DemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title    = @"v1.5 新特性";
    self.demoView = (V15DemoView *)self.view;
    self.model    = [[V15DemoModel alloc] init];
    self.bindings = [NSMutableArray array];
    self.scanHistory = [NSMutableString string];
    self.model.countValue = @0;  // biMap 初始値
    [self p_bindData];
    [self p_setupActions];
}

- (void)p_bindData {
    __weak typeof(self) weak = self;
    
    // ── ① transform ──────────────────────────────────────────────
    // 输入文本 → transform 统一转大写 → result label 显示大写版本。
    // transform 作用于整条链：twoWay(model) 的 receive 节点和 receive(label) 都收到大写值。
    // 注意：model.transformText 本身存的是大写后的值（receive 方向也经过 transform）。
    JHBinder
        .twoWay(self.model, @"transformText")
        .twoWayUI(self.demoView.transformField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.transformResultLabel, @"text")
        .transform(^id(id v) {
            return [v isKindOfClass:[NSString class]] ? [(NSString *)v uppercaseString] : v;
        })
        .store(self.bindings);
    
    // ── ② scan ───────────────────────────────────────────────────
    // 每次按键（EditingChanged）触发一次广播。
    // scan 累加器：每次广播计数 +1，与内容无关，直观展示状态累积。
    JHBinder
        .twoWay(self.model, @"scanText")
        .twoWayUI(self.demoView.scanField, @"text", UIControlEventEditingChanged)
        .observe(@"v15.scan", ^(id v) {
            // v 是 scan 返回的累加值（NSNumber 次数）
            weak.demoView.scanResultLabel.text =
                [NSString stringWithFormat:@"已触发 %@ 次", v];

            NSString *entry = [NSString stringWithFormat:@"%@→", v];
            [weak.scanHistory appendString:entry];
            // 只保留最近 8 次记录
            NSArray *parts = [weak.scanHistory componentsSeparatedByString:@"→"];
            if (parts.count > 9) {
                NSArray *recent = [parts subarrayWithRange:NSMakeRange(parts.count - 9, 8)];
                weak.scanHistory = [[recent componentsJoinedByString:@"→"] mutableCopy];
                [weak.scanHistory appendString:@"→"];
            }
            weak.demoView.scanHistoryLabel.text =
                [NSString stringWithFormat:@"计数轨迹：%@", weak.scanHistory];
        })
        .scan(@0, ^id(id acc, id __unused val) {
            // 每次广播累加 1，与内容无关
            return @([acc intValue] + 1);
        })
        .store(self.bindings);
    
    // ── ③ withPrevious ───────────────────────────────────────────
    // 每次输入后，接收节点收到 @[prevValue, newValue]，展示变化路径。
    JHBinder
        .twoWay(self.model, @"withPreviousText")
        .twoWayUI(self.demoView.withPreviousField, @"text", UIControlEventEditingChanged)
        .observe(@"v15.withPrevious", ^(id pair) {
            if (![pair isKindOfClass:[NSArray class]]) return;
            NSArray *p = pair;
            id prev = p[0];
            id now  = p[1];
            NSString *prevStr = ([prev isKindOfClass:[NSNull class]] || !prev) ? @"（空）" : prev;
            NSString *nowStr  = ([now  isKindOfClass:[NSNull class]] || !now)  ? @"（空）" : now;
            weak.demoView.withPreviousResultLabel.text =
            [NSString stringWithFormat:@"从 \"%@\"\n变为 \"%@\"", prevStr, nowStr];
        })
        .withPrevious()
        .store(self.bindings);
    
    // ── ④ biMap ──────────────────────────────────────────────────
    // model.countValue 存 NSNumber，biMapField 展示字符串。
    // forward：模型改变 → NSNumber 转字符串 → textField 显示、label 显示
    // backward：用户回车 → 字符串转 NSNumber → 写入 model.countValue
    JHBinder
        .twoWay(self.model, @"countValue")
        .twoWayUI(self.demoView.biMapField, @"text", UIControlEventEditingDidEndOnExit)
        .receive(self.demoView.biMapValueLabel, @"text")
        .nodeMap(^id(id v){
            // label 展示格式化的内容（v 是 forward 转换后的字符串）
            return [NSString stringWithFormat:@"model.countValue = %@", v];
        })
        .biMap(
               ^id(id v){ return [v description]; },          // forward:  NSNumber → NSString
               ^id(id v){ return @([(NSString *)v intValue]); } // backward: NSString → NSNumber
               )
        .fire()
        .store(self.bindings);
}

- (void)p_setupActions {
    [self.demoView.biMapIncrButton addTarget:self
                                      action:@selector(p_onIncrement)
                            forControlEvents:UIControlEventTouchUpInside];
    [self.demoView.biMapDecrButton addTarget:self
                                      action:@selector(p_onDecrement)
                            forControlEvents:UIControlEventTouchUpInside];
}

- (void)p_onIncrement {
    self.model.countValue = @(self.model.countValue.intValue + 1);
}
- (void)p_onDecrement {
    self.model.countValue = @(self.model.countValue.intValue - 1);
}

@end
