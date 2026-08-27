//
//  JHBinder.h
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//

/**
 * JHBinder — 轻量级 KVO + UIControl 数据绑定库（链式 DSL）
 *
 * ============================================================
 * 核心概念
 * ============================================================
 *
 * 【绑定链（Chain）】
 *   一条链由若干"节点（Node）"组成，共享同一个广播组（Group）。
 *   链内任意节点感知到值变化，就向组内其余节点广播新值。
 *
 * 【节点方向（Direction）】
 *
 *   ┌─────┬────────────────────┐
 *   │ twoWay   │ 既监听自身变化（IN）又接收广播（OUT）   │
 *   │ listen       │ 只监听自身变化（IN），不接收广播              │
 *   │ receive    │ 只接收广播（OUT），不监听自身变化          │
 *   │ observe   │ 纯 block 订阅，无 target，接收广播回调       │
 *   └─────┴────────────────────┘
 *
 * 【convertBlock（Map）】
 *   仅在节点【接收广播】时执行，用于转换收到的值再写入 target。
 *   节点自身触发广播时，原始值直接传出，不经过 convertBlock。
 *
 * 【filterBlock】
 *   链级全局拦截器，作用于整条链所有广播：
 *   - 返回 YES：广播正常传递给所有接收节点
 *   - 返回 NO：本次广播被丢弃，所有接收节点均不更新
 *   注意：filter 不区分写在链中的位置，对全链所有节点一致生效。
 *
 * 【生命周期】
 *   调用 .store(self.bindings) 将 JHBinder 存入外部 NSMutableArray。
 *   当 array 释放（VC dealloc 时置 nil 或 removeAllObjects）时，
 *   binder 自动 dealloc，触发所有 KVO / Target-Action 解绑。
 *   无需手动调用任何 unbind 方法。
 *
 * ============================================================
 * 使用示例
 * ============================================================
 *
 * @code
 * // 1. 双向绑定：model ↔ textField，单向驱动 label 和 counterLabel
 * JHBinder
 *     .twoWay(self.model, @"text")
 *     .twoWayUI(self.textField, @"text", UIControlEventEditingChanged)
 *     .receive(self.label, @"text")
 *     .receiveMap(self.counterLabel, @"text", ^id(NSString *v) {
 *         return [NSString stringWithFormat:@"%lu 字", v.length];
 *     })
 *     .filter(^BOOL(id old, id new) {
 *         return ((NSString *)new).length <= 20;   // 超 20 字丢弃广播
 *     })
 *     .store(self.bindings);
 *
 * // 2. twoWayUIMap：接收广播时转大写，广播自身变化时传原始值
 * JHBinder
 *     .twoWay(self.model, @"text")
 *     .twoWayUI(self.rawField, @"text", UIControlEventEditingChanged)
 *     .twoWayUIMap(self.upperField, @"text", UIControlEventEditingChanged, ^id(NSString *v) {
 *         return v.uppercaseString;
 *     })
 *     .store(self.bindings);
 *
 * // 3. MVVM：只监听 textField，驱动 loginBtn.enabled（不反向绑定）
 * JHBinder
 *     .listenUI(self.accountField, @"text", UIControlEventEditingChanged)
 *     .receive(self.loginBtn, @"enabled")
 *     .observe(@"account.changed", ^(id value) {
 *         NSLog(@"account = %@", value);
 *     })
 *     .store(self.bindings);
 * @endcode
 */

#import <UIKit/UIKit.h>
#import "JHBinderDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class JHBinder;

// MARK: - Block 类型别名（链式 DSL 所用）

/// 普通属性双向/单向绑定：.twoWay(target, keyPath)
typedef JHBinder *_Nonnull(^JHBinderBlock)(id target, NSString *keyPath);

/// UIControl 事件驱动绑定：.twoWayUI(control, keyPath, UIControlEventXxx)
typedef JHBinder *_Nonnull(^JHBinderUIBlock)(id target, NSString *keyPath, UIControlEvents event);

/// 带值转换的属性绑定：.receiveMap(target, keyPath, ^id(id v){ return ...; })
typedef JHBinder *_Nonnull(^JHBinderConvertBlock)(id target, NSString *keyPath, JHConvertBlock convert);

/// 带值转换的 UIControl 绑定：.twoWayUIMap(control, keyPath, event, ^id(id v){ return ...; })
typedef JHBinder *_Nonnull(^JHBinderUIConvertBlock)(id target, NSString *keyPath, UIControlEvents event, JHConvertBlock convert);

/// 纯 block 订阅，无 target：.observe(@"key", ^(id value){ ... })
typedef JHBinder *_Nonnull(^JHBinderObserveBlock)(NSString *key, JHOutBlock handler);

/// 链级广播拦截器：.filter(^BOOL(id old, id new){ return YES/NO; })
typedef JHBinder *_Nonnull(^JHBinderFilterBlock)(JHFilterBlock filter);

/// 无参数链式操作：.fire()  .distinct()  .once()
typedef JHBinder *_Nonnull(^JHBinderVoidBlock)(void);

/// 时间间隔操作：.debounce(0.3)  .delay(0.5)
typedef JHBinder *_Nonnull(^JHBinderIntervalBlock)(NSTimeInterval interval);

/// 标签字符串操作：.log(@"textField")
typedef JHBinder *_Nonnull(^JHBinderLabelBlock)(NSString *label);

/// 生命周期存储：.store(self.bindings)
typedef void(^JHBinderStoreBlock)(NSMutableArray *array);

/// 节点级 map（v1.3）：.nodeMap(^id(id v){ return ...; })
typedef JHBinder *_Nonnull(^JHBinderNodeMapBlock)(JHConvertBlock convert);

/// 节点级 filter（v1.3）：.nodeFilter(^BOOL(id v){ return YES/NO; })
typedef JHBinder *_Nonnull(^JHBinderNodeFilterBlock)(JHNodeFilterBlock filter);


// MARK: - JHBinder

@interface JHBinder : NSObject

// MARK: - 双向绑定（既监听 IN，又接收 OUT）

/**
 * 【链起始】对普通 NSObject 属性建立双向 KVO 绑定。
 *
 * 用法：JHBinder.twoWay(model, @"text")
 *
 * - 当 target.keyPath 被外部修改（KVO 触发），向链内其余节点广播新值。
 * - 当链内其他节点广播时，通过 KVC setValue:forKeyPath: 更新 target.keyPath。
 * - 通常用于绑定 Model / ViewModel 属性作为链的"数据源"节点。
 */
@property (class, nonatomic, readonly) JHBinderBlock twoWay;


/**
 * 【链起始】对 UIControl 建立双向绑定（Target-Action 监听 + KVO 接收）。
 *
 * 用法：JHBinder.twoWayUI(textField, @"text", UIControlEventEditingChanged)
 *
 * - 通过 Target-Action 监听指定 UIControlEvents，用户操作时向链广播。
 * - 接收广播时通过 KVC 把新值写回控件属性（如 text、value）。
 * - 适用于 UITextField、UISlider、UISwitch、UISegmentedControl 等所有 UIControl 子类。
 */
@property (class, nonatomic, readonly) JHBinderUIBlock twoWayUI;


/**
 * 【链起始】对普通 NSObject 属性建立带值转换的双向绑定。
 *
 * 用法：JHBinder.twoWayMap(label, @"text", ^id(NSNumber *v){ return v.stringValue; })
 *
 * convertBlock 的执行时机：
 *   - ✅ 接收广播时：收到的原始值先经过 convertBlock 转换，再写入 target.keyPath。
 *   - ❌ 广播自身变化时：直接把 target.keyPath 的原始值广播出去，不经过 convertBlock。
 *
 * 这意味着链内各节点存储的是"原始值"，显示层面的转换仅发生在该节点的显示端。
 */
@property (class, nonatomic, readonly) JHBinderConvertBlock twoWayMap;


/**
 * 【链起始】对 UIControl 建立带值转换的双向绑定。
 *
 * 用法：JHBinder.twoWayUIMap(upperField, @"text", UIControlEventEditingChanged,
 *                             ^id(NSString *v){ return v.uppercaseString; })
 *
 * convertBlock 仅在接收广播时执行（含义同 twoWayMap），广播时传原始值。
 * 适用于需要"显示转换但不污染数据源"的场景，如大写/格式化等。
 */
@property (class, nonatomic, readonly) JHBinderUIConvertBlock twoWayUIMap;


/**
 * 【链继续】在已有链上追加一个普通属性双向节点（含义同类属性 twoWay）。
 */
@property (nonatomic, readonly) JHBinderBlock twoWay;


/**
 * 【链继续】在已有链上追加一个 UIControl 双向节点（含义同类属性 twoWayUI）。
 */
@property (nonatomic, readonly) JHBinderUIBlock twoWayUI;


/**
 * 【链继续】在已有链上追加一个带转换的普通属性双向节点（含义同类属性 twoWayMap）。
 */
@property (nonatomic, readonly) JHBinderConvertBlock twoWayMap;


/**
 * 【链继续】在已有链上追加一个带转换的 UIControl 双向节点（含义同类属性 twoWayUIMap）。
 */
@property (nonatomic, readonly) JHBinderUIConvertBlock twoWayUIMap;


// MARK: - 单向监听（只 IN，向链广播，不接收广播）

/**
 * 【链起始】对普通 NSObject 属性建立单向 KVO 监听。
 *
 * 用法：JHBinder.listen(model, @"text")
 *
 * - 当 target.keyPath 变化时，向链内其余节点广播新值。
 * - 不接收链内广播，广播不会回写到该节点（单向数据源）。
 * - 适用于 ViewModel 属性作为"只写出，不被改"的只读数据源。
 */
@property (class, nonatomic, readonly) JHBinderBlock listen;


/**
 * 【链起始】对 UIControl 建立单向 Target-Action 监听。
 *
 * 用法：JHBinder.listenUI(textField, @"text", UIControlEventEditingChanged)
 *
 * - 用户操作触发事件时，读取 target.keyPath 值向链广播。
 * - 不接收广播，链内其他节点的变化不会写回该控件。
 * - 常用于"输入驱动逻辑，但逻辑结果不反写输入框"的 MVVM 场景。
 */
@property (class, nonatomic, readonly) JHBinderUIBlock listenUI;


/**
 * 【链继续】在已有链上追加一个普通属性单向监听节点（含义同类属性 listen）。
 */
@property (nonatomic, readonly) JHBinderBlock listen;


/**
 * 【链继续】在已有链上追加一个 UIControl 单向监听节点（含义同类属性 listenUI）。
 */
@property (nonatomic, readonly) JHBinderUIBlock listenUI;


// MARK: - 单向接收（只 OUT，接收广播，不监听自身变化）

/**
 * 【链继续】追加一个只接收广播的属性节点（无 convertBlock）。
 *
 * 用法：.receive(label, @"text")
 *
 * - 链内任意监听节点广播时，将新值通过 KVC 写入 target.keyPath。
 * - 自身属性变化不触发任何广播（单向终点）。
 * - 适用于显示层（UILabel、UIImageView 等）的纯被动更新。
 */
@property (nonatomic, readonly) JHBinderBlock receive;


/**
 * 【链继续】追加一个带值转换的只接收广播节点。
 *
 * 用法：.receiveMap(label, @"text", ^id(NSNumber *v){
 *           return [NSString stringWithFormat:@"%.0f%%", v.floatValue * 100];
 *       })
 *
 * - 收到广播后，先经过 convertBlock 转换值，再写入 target.keyPath。
 * - convertBlock 永远只在接收方向执行（该节点本身不监听，所以没有"广播方向"）。
 * - 适用于格式化显示、类型转换（NSNumber→NSString、float→百分比等）。
 */
@property (nonatomic, readonly) JHBinderConvertBlock receiveMap;


/**
 * 【链继续】追加一个纯 block 订阅节点（无 target，不写入任何属性）。
 *
 * 用法：.observe(@"unique.key", ^(id value) { NSLog(@"%@", value); })
 *
 * - 链内有广播时，handler block 被调用，参数为广播值（已经过该节点 convertBlock，如有）。
 * - key 仅作为节点唯一标识符，建议使用反向域名风格以便调试。
 * - 适用于副作用逻辑：日志、字数统计、按钮 enabled 状态更新等无法用 KVC 表达的操作。
 */
@property (nonatomic, readonly) JHBinderObserveBlock observe;


// MARK: - 过滤器 / 生命周期

/**
 * 【链级全局广播拦截器】设置值过滤条件，对整条链所有广播生效。
 *
 * 用法：.filter(^BOOL(id old, id new) {
 *           return ((NSString *)new).length <= 20;
 *       })
 *
 * - 返回 YES：广播继续传递，链内所有接收节点正常更新。
 * - 返回 NO：本次广播被丢弃，所有接收节点均不更新。
 *
 * 注意事项：
 * - filter 是链级全局的，无论写在链中哪个位置，对所有节点均一致生效。
 *   若只需对部分节点过滤，请拆成两条独立的链，或在 receiveMap/twoWayMap 的
 *   convertBlock 内进行条件处理。
 * - UIControl 节点触发广播时，old 参数为 nil（UIControl 不缓存旧值）。
 */
@property (nonatomic, readonly) JHBinderFilterBlock filter;


/**
 * 【生命周期绑定】将当前 JHBinder 存入外部 NSMutableArray，由调用方持有。
 *
 * 用法：.store(self.bindings)
 *   其中 self.bindings 是 ViewController 的 @property NSMutableArray *bindings。
 *
 * 工作原理：
 * - JHBinder 实例被 retain 进 array，其生命周期与 array 一致。
 * - 当 ViewController dealloc 时，self.bindings 随之释放，
 *   JHBinder dealloc 自动解除所有 KVO 和 Target-Action 绑定。
 * - 无需手动调用 unbindTarget: 等解绑方法。
 *
 * 若需提前解绑，可调用 [self.bindings removeAllObjects] 或
 * 使用 +unbindTarget: / +unbindTarget:keyPath: 显式解绑。
 */
@property (nonatomic, readonly) JHBinderStoreBlock store;


// MARK: - v1.2 新增：广播行为控制

/**
 * 【即时广播】链建立完成后，立刻用第一个监听节点的当前值广播一次。
 *
 * 用法：.fire()
 *
 * 适用场景：绑定建立时 label/UI 需要立即显示 model 当前值，
 * 而不必等到用户操作触发第一次变化。
 */
@property (nonatomic, readonly) JHBinderVoidBlock fire;


/**
 * 【去重】UIControl 相同值不重复广播。
 *
 * 用法：.distinct()
 *
 * KVO 路径已内置此行为，distinct 主要对 UIControl 节点生效。
 * 适用场景： UISlider 拖动时可能频繁触发相同值，可减少不必要广播。
 */
@property (nonatomic, readonly) JHBinderVoidBlock distinct;


/**
 * 【单次触发】首次广播完成后，自动移除所有节点（解绑）。
 *
 * 用法：.once()
 *
 * 适用场景：只关心一次变化，如加载完成回调、首次登录成功等。
 * 与 store 配合使用：广播后节点被移除，binder 仍在 array，下次就算 model 变化也不会再广播。
 */
@property (nonatomic, readonly) JHBinderVoidBlock once;


/**
 * 【防抖】停止触发后延迟 N 秒广播，连续触发时重置计时器。
 *
 * 用法：.debounce(0.3)  // 0.3秒内无再次输入才广播
 *
 * 适用场景：搜索框输入联网请求、频繁需要节流的 UIControl 事件。
 * 注：debounce 优先于 delay，二者同时设置时只生效 debounce。
 */
@property (nonatomic, readonly) JHBinderIntervalBlock debounce;


/**
 * 【延迟】每次触发后延迟 N 秒广播，不取消前次。
 *
 * 用法：.delay(0.5)  // 每次触发后 0.5 秒广播
 *
 * 与 debounce 区别：delay 每次都广播只是延迟；debounce 会噸掉中间快速变化。
 */
@property (nonatomic, readonly) JHBinderIntervalBlock delay;


/**
 * 【调试日志】开启广播日志，每次广播打印：[JHBinder:label] nodeID → value。
 *
 * 用法：.log(@"textField")
 *
 * 建议仅在调试阶段使用，正式上线前移除。
 */
@property (nonatomic, readonly) JHBinderLabelBlock log;


// MARK: - v1.3 新增：节点级 map / filter

/**
 * 【节点级 map】对【上一个 receive / twoWay 节点】设置独立的值转换。
 *
 * 用法：.receive(redLabel, @"text").nodeMap(^id(NSNumber *v){
 *              return [NSString stringWithFormat:@"❌ %@分", v];
 *          })
 *
 * - 实质是设置该节点的 convertBlock，与在 receiveMap 中内联传入效果相同。
 * - 覆盖当前节点已有的 convertBlock（如果有）。
 * - 必须紧跟在 .receive() / .receiveMap() 之后。
 */
@property (nonatomic, readonly) JHBinderNodeMapBlock nodeMap;


/**
 * 【节点级 filter】对【上一个 receive / twoWay 节点】设置独立的过滤器。
 *
 * 用法：.receive(redLabel, @"text")
 *          .nodeFilter(^BOOL(NSNumber *v){ return v.intValue < 60; })
 *
 * - 返回 NO 时跳过该节点，其他节点不受影响（区别于链级 filter 会丢弃整条链广播）。
 * - 参数 value 是【原始广播值】，即 nodeMap 转换之前的值（filter 先于 map 执行）。
 * - 必须紧跟在 .receive() 之后（可配合 nodeMap 一起使用）。
 */
@property (nonatomic, readonly) JHBinderNodeFilterBlock nodeFilter;


// MARK: - v1.3 新增： combineLatest

/**
 * 【链起始】多源合并：任意源发射时，收集所有源的最新值，经 combineBlock 产出单一值广播。
 *
 * 用法：
 * @code
 * [JHBinder combineLatest:@[
 *     JHBinder.listen(modelA, @"firstName"),
 *     JHBinder.listen(modelB, @"lastName")
 * ] combineMap:^id(NSArray *v){
 *     return [NSString stringWithFormat:@"%@ %@", v[0], v[1]];
 * }]
 * .receive(self.fullNameLabel, @"text")
 * .store(self.bindings);
 * @endcode
 *
 * 语义（标准 combineLatest）：
 * - 所有源至少各发射过一次后，combine 才开始广播。
 * - 之后任意源发射，就用最新快照重新合并。
 *
 * 生命周期：
 * - 只需 .store() combine binder；
 * - sources 的生命周期由 combine binder 内部持有，无需单独 store。
 *
 * @param sources     源 JHBinder 数组，每个必须包含至少一个 listen / twoWay 节点
 * @param combineBlock values 按 sources 顺序排列；返回 nil 则广播 NSNull
 */
+ (JHBinder *)combineLatest:(NSArray<JHBinder *> *)sources
                 combineMap:(id _Nullable (^)(NSArray *values))combineBlock;


// MARK: - 显式解绑（全局）

/**
 * 解除指定 target 的所有绑定（跨所有链）。
 *
 * 使用场景：target 被提前释放前手动清理，或在特殊时机主动断开所有关联。
 */
+ (void)unbindTarget:(id)target;


/**
 * 解除指定 target 在指定 keyPath 上的绑定。
 *
 * 使用场景：同一 target 参与多条链，只需解除某个 keyPath 的绑定。
 */
+ (void)unbindTarget:(id)target keyPath:(NSString *)keyPath;


/**
 * 查询指定 target 的 keyPath 是否已存在绑定。
 *
 * @return YES 表示该 keyPath 已在某条链中注册为节点。
 */
+ (BOOL)isBound:(id)target keyPath:(NSString *)keyPath;


@end

NS_ASSUME_NONNULL_END
