//
//  V18DemoViewController.m
//  JHBinderDemo
//
//  演示 v1.8 五个新 API：
//    ① format(fmt)           — 格式化字符串语法糖
//    ② notNil                — 屏蔽 nil / NSNull
//    ③ required              — 屏蔽 nil / NSNull / 空字符串
//    ④ pausable(signal)      — 动态开关（gate 信号控制链通断）
//    ⑤ rebindTo:keyPath:     — 热替换 KVO 监听节点 target
//
//  关键设计原则：
//  jh_isUpdating 防循环机制会在"链 A.receive(model)"写入期间屏蔽
//  同一 model 属性的其他 KVO 链（链 B）。因此，凡需要 UIControl → 链 → UI
//  的场景，必须合并成"单链直达"，不通过 model 中转。
//  例外：按钮 Action 直接赋值 model 属性（ObjC 赋值，非 JHBinder receive），
//  不经过 jh_isUpdating，下游 KVO 链完全正常。
//

#import "V18DemoViewController.h"
#import "V18DemoView.h"
#import "V18DemoModel.h"
#import "JHBinderKit.h"

@interface V18DemoViewController ()
@property (nonatomic, strong) V18DemoView    *demoView;
@property (nonatomic, strong) V18DemoModel   *model;     ///< notNil / isLoggedIn 专用
@property (nonatomic, strong) V18DemoModel   *cardA;     ///< ⑤ rebind
@property (nonatomic, strong) V18DemoModel   *cardB;     ///< ⑤ rebind
@property (nonatomic, strong) NSMutableArray *bindings;

/// ④ pausable gate binder：强持有，不 store（生命周期随 VC 释放）
@property (nonatomic, strong) JHBinder       *loginGateBinder;
/// ⑤ rebind：保留引用以调用 rebindTo:keyPath:
@property (nonatomic, strong) JHBinder       *cardBinder;
/// ⑤ rebind：当前被监听的 model（A 或 B）
@property (nonatomic, weak)   V18DemoModel   *currentCardModel;
@end

@implementation V18DemoViewController

static int sRebindCounter = 0;

- (void)loadView {
    self.demoView = [[V18DemoView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = self.demoView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title    = @"v1.8 新特性";
    self.bindings = [NSMutableArray array];

    _model = [V18DemoModel new];
    _cardA = [V18DemoModel new]; _cardA.cardName = @"cardA";
    _cardB = [V18DemoModel new]; _cardB.cardName = @"cardB";
    _currentCardModel = _cardA;

    [self p_bindFormat];
    [self p_bindNotNil];
    [self p_bindRequired];
    [self p_bindPausable];
    [self p_bindRebind];
    [self p_addActions];
}

// MARK: - ① format
// 单链：listenUI(slider/stepper) → format → receive(label)
// 不经过 model，无 jh_isUpdating 问题。

- (void)p_bindFormat {
    V18DemoView *v = self.demoView;

    // slider → format(@"¥%.2f") → priceLabel
    JHBinder
        .listenUI(v.priceSlider, @"value", UIControlEventValueChanged)
        .format(@"¥%.2f")
        .receive(v.priceLabel, @"text")
        .store(self.bindings);

    // stepper value 是 double，先 transform 转 int，再 format 成 "共 N 件"
    JHBinder
        .listenUI(v.countStepper, @"value", UIControlEventValueChanged)
        .transform(^id(id val){ return @(((NSNumber *)val).intValue); })
        .format(@"共 %@ 件")
        .receive(v.countLabel, @"text")
        .store(self.bindings);
}

// MARK: - ② notNil
// 三个按钮直接通过 ObjC 赋值触发 KVO，不经过 jh_isUpdating，下游链正常工作。

- (void)p_bindNotNil {
    JHBinder
        .listen(_model, @"notNilValue")
        .notNil
        .receiveMap(self.demoView.notNilResultLabel, @"text", ^id(id v) {
            return [NSString stringWithFormat:@"✅ 收到：%@", v];
        })
        .store(self.bindings);
}

// MARK: - ③ required
// 单链：listenUI(textField) → required(屏蔽空串) → receive(label)
// 不通过 model，无 jh_isUpdating 问题。

- (void)p_bindRequired {
    JHBinder
        .listenUI(self.demoView.requiredField, @"text", UIControlEventEditingChanged)
        .required
        .receive(self.demoView.requiredLabel, @"text")
        .store(self.bindings);
}

// MARK: - ④ pausable
// gate binder 独立监听 isLoggedIn；textField 单链直达 label（绕过 model）。

- (void)p_bindPausable {
    V18DemoView *v = self.demoView;

    // gate binder：监听 isLoggedIn，更新 _lastEffectiveValue 供 pausable 读取
    // 不需要 store：VC 生命周期内强持有，dealloc 时自动解绑
    _loginGateBinder = JHBinder
        .listen(_model, @"isLoggedIn");

    // isLoggedIn → loginStateLabel（按钮直接赋值，ObjC 赋值触发 KVO，正常工作）
    JHBinder
        .listen(_model, @"isLoggedIn")
        .receiveMap(v.loginStateLabel, @"text", ^id(id val) {
            return (val && val != [NSNull null] && [val boolValue]) ? @"已登录 ✅" : @"未登录 ❌";
        })
        .fire()
        .store(self.bindings);

    // textField → pausable(loginGate) → pausableResultLabel
    // 单链：UIControl → pausable → receive，gate 决定通断
    JHBinder
        .listenUI(v.pausableField, @"text", UIControlEventEditingChanged)
        .pausable(_loginGateBinder)
        .receiveMap(v.pausableResultLabel, @"text", ^id(id val) {
            return [NSString stringWithFormat:@"🔒 内容：%@", val];
        })
        .store(self.bindings);
}

// MARK: - ⑤ rebind
// 初始绑定 cardA；通过 rebindTo:keyPath: 热替换 target，不重建链。

- (void)p_bindRebind {
    _cardBinder = JHBinder
        .listen(_cardA, @"cardName")
        .receive(self.demoView.rebindCardLabel, @"text")
        .fire();
    [self.bindings addObject:_cardBinder];
}

// MARK: - Actions

- (void)p_addActions {
    V18DemoView *v = self.demoView;

    // ② notNil
    [v.notNilNilButton   addTarget:self action:@selector(onNilTap)    forControlEvents:UIControlEventTouchUpInside];
    [v.notNilNullButton  addTarget:self action:@selector(onNullTap)   forControlEvents:UIControlEventTouchUpInside];
    [v.notNilValueButton addTarget:self action:@selector(onValueTap)  forControlEvents:UIControlEventTouchUpInside];

    // ④ 登录切换
    [v.loginToggleButton addTarget:self action:@selector(onLoginToggle) forControlEvents:UIControlEventTouchUpInside];

    // ⑤ rebind
    [v.rebindToAButton    addTarget:self action:@selector(onRebindA)    forControlEvents:UIControlEventTouchUpInside];
    [v.rebindToBButton    addTarget:self action:@selector(onRebindB)    forControlEvents:UIControlEventTouchUpInside];
    [v.rebindUpdateButton addTarget:self action:@selector(onUpdateCard) forControlEvents:UIControlEventTouchUpInside];
}

// ② notNil：按钮直接 ObjC 赋值，不走 JHBinder receive，jh_isUpdating 不生效
- (void)onNilTap   { _model.notNilValue = nil; }
- (void)onNullTap  { _model.notNilValue = [NSNull null]; }
- (void)onValueTap { _model.notNilValue = @"有效值 🎉"; }

// ④ pausable：切换 isLoggedIn，按钮直接 ObjC 赋值
- (void)onLoginToggle {
    BOOL isOn = _model.isLoggedIn && _model.isLoggedIn != [NSNull null] && [_model.isLoggedIn boolValue];
    _model.isLoggedIn = isOn ? @(NO) : @(YES);
    NSString *btnTitle = isOn ? @"▶ 点击登录" : @"⏸ 点击登出";
    [self.demoView.loginToggleButton setTitle:btnTitle forState:UIControlStateNormal];
    self.demoView.loginStateLabel.backgroundColor =
        isOn ? [UIColor systemGrayColor] : [UIColor systemGreenColor];
}

// ⑤ rebind
- (void)onRebindA {
    _currentCardModel = _cardA;
    [_cardBinder rebindTo:_cardA keyPath:@"cardName"];
}

- (void)onRebindB {
    _currentCardModel = _cardB;
    [_cardBinder rebindTo:_cardB keyPath:@"cardName"];
}

- (void)onUpdateCard {
    sRebindCounter++;
    NSString *which = (_currentCardModel == _cardA) ? @"A" : @"B";
    _currentCardModel.cardName = [NSString stringWithFormat:@"card%@ #%d", which, sRebindCounter];
}

@end
