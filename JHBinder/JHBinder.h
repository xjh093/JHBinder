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
 *
 * ============================================================
 * ⚠️ 常见陷阱：双链串联中间经过 model 属性（链 A → model → 链 B）
 * ============================================================
 *
 * JHBinder 内部使用 `jh_isUpdating` 标记防止双向绑定产生无限循环。
 * 当链 A 通过 `.receive(model, keyPath)` 写入 model 属性时，
 * JHBinder 会将该 model 实例标记为 `jh_isUpdating = YES`，
 * 此期间同一 model 属性的 **所有其他 KVO 链（链 B）** 都会被直接跳过。
 *
 * ❌ 错误示例（双链串联，链 B 永远不会触发）：
 * @code
 * // 链 A：UIControl → receive(model)
 * JHBinder
 *     .listenUI(textField, @"text", UIControlEventEditingChanged)
 *     .receive(self.model, @"keyword")       // 写入时 model.jh_isUpdating = YES
 *     .store(self.bindings);
 *
 * // 链 B：listen(model) → 其他操作 → receive(label)
 * JHBinder
 *     .listen(self.model, @"keyword")         // KVO 回调被 jh_isUpdating 拦截 → 永远不执行
 *     .required
 *     .receive(self.label, @"text")
 *     .store(self.bindings);
 * @endcode
 *
 * ✅ 正确方案 1：合并单链（UIControl 直达 label，无需 model 中转）
 * @code
 * JHBinder
 *     .listenUI(textField, @"text", UIControlEventEditingChanged)
 *     .required                               // 直接在链上过滤
 *     .receive(self.label, @"text")
 *     .store(self.bindings);
 * @endcode
 *
 * ✅ 正确方案 2：用 ObjC 代码直接赋值 model（不经过 JHBinder 的 KVC 写入路径）
 * @code
 * // 按钮 Action 或手动赋值，jh_isUpdating 不会被设置
 * self.model.keyword = textField.text;        // 链 B 的 KVO 正常触发 ✓
 * @endcode
 *
 * 规律总结：
 *   - 链 A 通过 .receive / .twoWay 写入 model 时：链 B 的 KVO 被屏蔽
 *   - 直接用 ObjC 代码赋值 model（setter / 直接属性赋值）时：链 B 正常
 *   - 同一条链内多个节点（receive(model) 与 receive(label) 并存）：正常，
 *     因为它们在同一次 broadcastBlock 里顺序写入，不走 KVO 回调路径
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

/// 默认值（v1.4）：.defaultValue(@"占位符")
typedef JHBinder *_Nonnull(^JHBinderDefaultBlock)(id _Nullable value);

/// 跳过/次数限制（v1.4）：.skip(1)  .take(3)
typedef JHBinder *_Nonnull(^JHBinderCountBlock)(NSUInteger count);

/// 链级值变换（v1.5）：.transform(^id(id v){ return ...; })
typedef JHBinder *_Nonnull(^JHBinderTransformBlock)(JHConvertBlock convert);

/// 累加器（v1.5）：.scan(@0, ^id(id acc, id val){ return ...; })
typedef JHBinder *_Nonnull(^JHBinderScanBlock)(id _Nullable initialValue, JHAccumulateBlock accumulator);

/// 双向映射（v1.5）：.biMap(forward, backward)
typedef JHBinder *_Nonnull(^JHBinderBiMapBlock)(JHConvertBlock forward, JHConvertBlock backward);

/// 内联副作用（v1.6）：.tap(^(id v){ ... })
typedef JHBinder *_Nonnull(^JHBinderTapBlock)(JHOutBlock tapHandler);

/// 谓词流控（v1.6）：.takeWhile(^BOOL(id v){ ... })  .skipWhile(^BOOL(id v){ ... })
typedef JHBinder *_Nonnull(^JHBinderPredicateBlock)(JHNodeFilterBlock predicate);

/// withLatestFrom（v1.6）：.withLatestFrom(otherBinder)
typedef JHBinder *_Nonnull(^JHBinderWithLatestFromBlock)(JHBinder *other);

/// pluck（v1.7）：.pluck(@"data.user.name")  从广播对象用 KVC 提取值
typedef JHBinder *_Nonnull(^JHBinderPluckBlock)(NSString *keyPath);

/// timeout（v1.7）：.timeout(4.0, @"超时提示")  t 秒无广播则发出 fallback
typedef JHBinder *_Nonnull(^JHBinderTimeoutBlock)(NSTimeInterval interval, id _Nullable fallback);

/// combine（v1.7）：.combine(other, ^id(NSArray *vs){ return vs; })
typedef JHBinder *_Nonnull(^JHBinderCombineBlock)(JHBinder *other, id _Nullable (^combineMap)(NSArray *values));

/// format（v1.8）：.format(@"¥%.2f")  .format(@"共 %@ 件")
typedef JHBinder *_Nonnull(^JHBinderFormatBlock)(NSString *format);

/// 引用捕获（v1.8）：.assignTo(&_binder) 将 binder 赋值给外部变量，返回 self 以继续链式调用
/// 用法：.assignTo(&_nameBinder).store(self.bindings)
typedef JHBinder *_Nonnull(^JHBinderAssignBlock)(JHBinder * __strong _Nullable * _Nonnull outRef);


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

/**
 * 【引用捕获】将 binder 赋值给指定变量，同时返回 self，可继续链式调用。
 *
 * 用法：.assignTo(&_nameBinder).store(self.bindings)
 *
 * 典型场景：Cell 复用时需要持有 binder 引用以调用 rebindTo:keyPath:。
 * 对比原写法：
 *   _nameBinder = JHBinder.listen(...).receive(...).fire();
 *   [self.bindings addObject:_nameBinder];
 * 新写法（一行链式完成）：
 *   JHBinder.listen(...).receive(...).fire().assignTo(&_nameBinder).store(self.bindings);
 */
@property (nonatomic, readonly) JHBinderAssignBlock assignTo;


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


// MARK: - v1.6 新增：merge

/**
 * 【多源合并】任意一个源广播时，透传其值向下游广播。
 *
 * 用法：
 *   [JHBinder merge:@[
 *       JHBinder.listen(modelA, @"fieldA"),
 *       JHBinder.listen(modelB, @"fieldB"),
 *   ]]
 *   .observe(@"any", ^(id v){ ... })
 *   .store(self.bindings);
 *
 * 与 combineLatest 的区别：
 *   - combineLatest：等所有源都有值后，把最新快照合并为数组广播
 *   - merge：任一源触发，直接透传该源的值（不等待其他源）
 *
 * 适用场景：多个输入源触发同一个下游处理逻辑（如多字段变化→统一表单校验）。
 */
+ (JHBinder *)merge:(NSArray<JHBinder *> *)sources;

/**
 * 【v1.7 定时器源】每隔 interval 秒广播一次递增的 NSNumber（0, 1, 2…）。
 *
 * 用法：
 *   JHBinder.interval(1.0).take(60).receive(...)  // 每秒触发，共 60 次
 *   JHBinder.interval(0.5).takeUntil(stopSignal)  // 配合 takeUntil 手动停止
 *
 * 注意：定时器随 JHBinder 实例生命周期自动停止（binder store 到 bindings，
 *   removeAll 时 binder 释放，定时器也随之销毁）。
 */
@property (class, nonatomic, readonly) JHBinderIntervalBlock interval;

/// 直接调用版（等价于 JHBinder.interval(t)），方便需要明确方法名的场景
+ (JHBinder *)intervalBinder:(NSTimeInterval)interval;


// MARK: - v1.4 新增：广播流控制

/**
 * 【默认值】广播值为 nil 或 NSNull 时，替换为指定默认值。
 *
 * 用法：.defaultValue(@"未知用户")
 *
 * 适用场景：模型属性初始为 nil，配合 fire() 可让标签立即显示占位文字。
 */
@property (nonatomic, readonly) JHBinderDefaultBlock defaultValue;


/**
 * 【跳过】忽略前 N 次广播，第 N+1 次才开始正常更新接收节点。
 *
 * 用法：.skip(1)   // 跳过第一次（如绑定建立时的初始广播）
 *
 * 注意：skip 与 fire 配合使用时，fire 触发的那次也会被跳过。
 */
@property (nonatomic, readonly) JHBinderCountBlock skip;


/**
 * 【次数限制】广播 N 次后自动解绑（.once() 等价于 .take(1))。
 *
 * 用法：.take(3)   // 只更新前 3 次，之后自动解绑
 *
 * 适用场景：加载动画、新手引导等只需有限次更新的场景。
 */
@property (nonatomic, readonly) JHBinderCountBlock take;


/**
 * 【前沿节流】窗口期内只允许第一次广播通过，后续触发丢弃。
 *
 * 用法：.throttle(1.0)  // 每秒最多广播一次
 *
 * 与 debounce 区别：
 *   - throttle：第一次立即通过，窗口期内后续丢弃（限频）
 *   - debounce：停止触发 N 秒后才广播（消抖）
 *
 * 适用场景：滚动位置上报、页面曝光数据采集等高频事件限频。
 */
@property (nonatomic, readonly) JHBinderIntervalBlock throttle;


/**
 * 【前沿 + 后沿节流】第一次立即通过，窗口期内最后一次被压制的值在窗口结束时补发。
 *
 * 用法：.throttleTrailing(1.0)
 *
 * 行为：
 *   t=0s  输入 A  → 立即广播 A（前沿）
 *   t=0.3 输入 B  → 压制
 *   t=0.6 输入 C  → 压制
 *   t=1.0 窗口结束 → 补发 C（后沿）
 *   t=1.5 输入 D  → 立即广播 D（新窗口前沿）
 *
 * 适用场景：实时预览且不过于频繁、需要最终结果的场景。
 */
@property (nonatomic, readonly) JHBinderIntervalBlock throttleTrailing;


/**
 * 【后沿节流】窗口内所有事件均被压制，窗口结束时将最后一个值一次性广播。
 *
 * 用法：.throttleTrailingOnly(1.0)
 *
 * 行为：
 *   t=0   输入 A  → 压制，开始计时
 *   t=0.3 输入 B  → 压制，更新待发值（不重置计时器）
 *   t=0.6 输入 C  → 压制，更新待发值
 *   t=1.0 窗口结束 → 广播 C
 *   t=1.5 输入 D  → 开始新窗口...
 *
 * 与 debounce 区别：debounce 每次输入重置计时器（消抖），
 *   throttleTrailingOnly 窗口开始后计时器不重置（保证最大延迟）。
 *
 * 适用场景：需要限制更新频率且不希望首个就触发的场景。
 */
@property (nonatomic, readonly) JHBinderIntervalBlock throttleTrailingOnly;


// MARK: - v1.5 值变换扩展

/**
 * 【链级值变换】广播前对整条链的值统一转换，作用于所有接收节点。
 *
 * 用法：.transform(^id(id v){ return [v uppercaseString]; })
 *
 * 与 nodeMap 区别：nodeMap 只对紧接其后的单个 receive 节点生效；
 *   transform 对链内所有节点生效（相当于"链前置 map"）。
 *
 * 适用场景：全局格式化（如统一大写）、类型转换（如 NSNumber→NSString）。
 */
@property (nonatomic, readonly) JHBinderTransformBlock transform;


/**
 * 【累加器】每次广播时基于上次累加结果和当前值生成新值。
 *
 * 用法：.scan(@0, ^id(id acc, id val){ return @([acc intValue] + [val length]); })
 *
 * 行为：
 *   第1次广播 "hi"   → accumulator(@0, "hi")     = @2   → 接收节点收到 @2
 *   第2次广播 "hello" → accumulator(@2, "hello") = @7   → 接收节点收到 @7
 *
 * 适用场景：累计输入字数、历史状态追踪、事件计数。
 */
@property (nonatomic, readonly) JHBinderScanBlock scan;


/**
 * 【双值打包】广播时将上一次广播值和当前值打包为数组 @[prevValue, newValue]。
 *
 * 用法：.withPrevious()
 *   接收节点：.observe(@"key", ^(id pair){ NSArray *p=pair; NSLog(@"%@ → %@", p[0], p[1]); })
 *
 * 首次广播时 prevValue 为 NSNull。
 *
 * 适用场景：展示"从 X 变为 Y"、差值计算、变化方向判断。
 */
@property (nonatomic, readonly) JHBinderVoidBlock withPrevious;


/**
 * 【双向映射】对同一条链定义两个方向的转换：模型→UI（forward）和 UI→模型（backward）。
 *
 * 用法：
 *   .biMap(
 *       ^id(id v){ return [v stringValue]; },    // forward:  NSNumber → NSString（模型→UI）
 *       ^id(id v){ return @([v intValue]); }      // backward: NSString → NSNumber（UI→模型）
 *   )
 *
 * 应用规则：
 *   - 广播源为 KVO（模型属性变化） → 应用 forward
 *   - 广播源为 UIControl（用户输入） → 应用 backward
 *
 * 适用场景：模型存 NSNumber、UI 展示 NSString，需要双向自动转换。
 */
@property (nonatomic, readonly) JHBinderBiMapBlock biMap;


// MARK: - v1.6 流控扩展

/**
 * 【初始值广播】绑定建立后立即广播指定值，不依赖节点的当前属性值。
 *
 * 区别于 fire()：fire 读取第一个监听节点的当前属性值；startWith 使用你指定的值。
 *
 * 用法：.startWith(@"加载中...")
 *
 * 适用场景：UI 初始状态与模型初始值不同时；或模型属性尚未赋值但 UI 需要先显示占位内容。
 */
@property (nonatomic, readonly) JHBinderDefaultBlock startWith;


/**
 * 【内联副作用】链中途执行 block，不消费、不修改广播值，链继续向下传播。
 *
 * 用法：.tap(^(id v){ [Analytics track:@"event" value:v]; })
 *
 * 与 observe 的区别：
 *   - observe 是终端节点，接收广播并展示/处理结果
 *   - tap 是中间节点，用于埋点、日志等副作用，不影响后续节点
 *
 * 可在同一链中多次调用，按添加顺序依次执行。
 */
@property (nonatomic, readonly) JHBinderTapBlock tap;


/**
 * 【布尔取反】将广播值作为 BOOL 取反后传递给所有接收节点。
 *
 * 用法：.negate()
 *   等价于 .transform(^id(id v){ return @(![v boolValue]); })
 *
 * 适用场景：model.isLoading = YES → button.enabled = NO（最常见的反向绑定）。
 */
@property (nonatomic, readonly) JHBinderVoidBlock negate;


/**
 * 【恒定映射】无论源值是什么，接收节点总收到同一个固定值。
 *
 * 用法：.mapTo(@YES)
 *   等价于 .transform(^id(id _){ return @YES; })
 *
 * 适用场景：把任意变化信号转换为一个固定的触发信号；或统一多个不同值到同一标志。
 */
@property (nonatomic, readonly) JHBinderDefaultBlock mapTo;


/**
 * 【自定义去重比较器】使用自定义逻辑判断两个值是否"相同"，相同则跳过广播。
 *
 * 用法：.distinctWhen(^BOOL(id old, id new){ return [old isEqualToString:new ignoreCase:YES]; })
 *   comparator 返回 YES → 视为相同 → 跳过；返回 NO → 视为不同 → 广播
 *
 * 与 distinct() 的区别：distinct 使用 isEqual；distinctWhen 允许自定义相等逻辑。
 *
 * 适用场景：忽略大小写的字符串比较、数值在容差范围内视为相等、自定义模型对象比较。
 */
@property (nonatomic, readonly) JHBinderFilterBlock distinctWhen;


/**
 * 【满足条件时广播】每次广播前检查谓词；谓词首次返回 NO 时，该值不广播并自动解绑整条链。
 *
 * 用法：.takeWhile(^BOOL(id v){ return [v intValue] < 10; })
 *
 * 行为：
 *   谓词返回 YES → 正常广播
 *   谓词首次返回 NO → 不广播该值，同时 removeAllNodes（自动解绑）
 *
 * 适用场景：重试计数不超过 N 次、进度未完成时持续更新、倒计时归零时停止。
 */
@property (nonatomic, readonly) JHBinderPredicateBlock takeWhile;


/**
 * 【跳过直到条件不满足】谓词返回 YES 期间跳过所有广播；首次返回 NO 后恢复正常（不可逆）。
 *
 * 用法：.skipWhile(^BOOL(id v){ return [(NSArray *)v count] == 0; })
 *
 * 行为：
 *   谓词返回 YES → 跳过广播（不解绑）
 *   谓词首次返回 NO → 进入正常广播，之后忽略谓词
 *
 * 适用场景：数据加载完成前忽略所有变化、首次满足条件后持续响应。
 */
@property (nonatomic, readonly) JHBinderPredicateBlock skipWhile;


/**
 * 【触发+采样】主源触发时，取 other 的最新值，合并为 @[primaryValue, sampledValue]。
 *
 * 用法：
 *   JHBinder *categoryBinder = JHBinder.listen(self.model, @"category");
 *
 *   JHBinder
 *       .listen(self.model, @"keyword")
 *       .debounce(0.3)
 *       .withLatestFrom(categoryBinder)
 *       .observe(@"search", ^(id pair) {
 *           NSArray *p = pair;  // p[0]=keyword, p[1]=latestCategory
 *           [self p_searchKeyword:p[0] category:p[1]];
 *       })
 *       .store(self.bindings);
 *   // categoryBinder 由 withLatestFrom 强持有，无需单独 store
 *
 * 注意：other 的首次采样值在其第一次广播后才有效；首次广播前采样结果为 NSNull。
 *
 * 适用场景：搜索框（触发）+ 分类筛选（采样）；提交按钮（触发）+ 表单内容（采样）。
 */
@property (nonatomic, readonly) JHBinderWithLatestFromBlock withLatestFrom;


// MARK: - v1.7 新增操作符

/**
 * 【takeUntil】当 signal 链首次广播时，自动解绑整条链。
 *
 * 用法：
 *   JHBinder.interval(1.0)
 *       .takeUntil(stopSignalBinder)   // stopSignalBinder 广播 → ticker 停止
 *       .receive(...)
 *       .store(self.bindings);
 *
 * 注意：signal binder 由当前 binder 强持有，无需单独 store。
 * signal 触发后，当前链 removeAllNodes，signal 上的监听节点也同步移除。
 */
@property (nonatomic, readonly) JHBinderWithLatestFromBlock takeUntil;

/**
 * 【pluck】用 KVC keyPath 从广播对象（NSDictionary / 自定义对象）中提取子值。
 *
 * 用法：
 *   .pluck(@"data.user.name")  → 广播值由 dict/obj 变为 name 字符串
 *
 * 若 keyPath 不存在或发生异常，广播值为 nil。
 * 可与其他 transform 链式组合，pluck 相当于一种 transform 语法糖。
 */
@property (nonatomic, readonly) JHBinderPluckBlock pluck;

/**
 * 【bufferCount】积累 n 个值后，打包为 NSArray 一次性广播。
 *
 * 用法：
 *   .bufferCount(3)   // 每攒够 3 个值，向下游广播 @[v1, v2, v3]
 *
 * 与 bufferTime 互斥：同时设置时 bufferCount 优先（bufferTime 仅作超时 flush）。
 */
@property (nonatomic, readonly) JHBinderCountBlock bufferCount;

/**
 * 【bufferTime】积累 t 秒内的所有值，到期打包为 NSArray 广播。
 *
 * 用法：
 *   .bufferTime(2.0)   // 每 2 秒将这段时间内的所有值合并为数组广播一次
 *
 * 如果 t 内没有值，不广播（静默）。
 */
@property (nonatomic, readonly) JHBinderIntervalBlock bufferTime;

/**
 * 【timeout】若 t 秒内没有收到新广播，自动向下游发出 fallback 值。
 *
 * 用法：
 *   .timeout(5.0, @"⏰ 连接超时")   // 5 秒无响应 → 标签显示超时提示
 *
 * 每次成功广播后自动重置计时器；fallback 广播后计时器重新启动（循环超时）。
 * 如需只触发一次，配合 .take(1) / .once 使用。
 */
@property (nonatomic, readonly) JHBinderTimeoutBlock timeout;

/**
 * 【sample】每隔 t 秒，把最近一次有效广播值重新推送到接收节点（降频采样）。
 *
 * 用法：
 *   .sample(1.0)   // 无论源广播多频繁，UI 最多每秒更新一次
 *
 * sample 直接将 lastEffectiveValue（已变换后的值）推送接收节点，
 * 不再重新执行 transform/biMap/scan 等管道，避免重复计算。
 */
@property (nonatomic, readonly) JHBinderIntervalBlock sample;

/**
 * 【combine】combineLatest 的实例方法版本；更易于链式组合。
 *
 * 用法：
 *   JHBinder *combined =
 *       JHBinder.listen(self.model, @"a")
 *               .combine(JHBinder.listen(self.model, @"b"),
 *                        ^id(NSArray *vs){ return [vs[0] stringByAppendingString:vs[1]]; });
 *   combined.receive(label, @"text").store(self.bindings);
 *
 * 等价于 [JHBinder combineLatest:@[binderA, binderB] combineMap:block]。
 * 返回值是新的 combined binder，需要继续在其上调用 .receive / .store。
 */
@property (nonatomic, readonly) JHBinderCombineBlock combine;

/**
 * 【elementAt】只对第 n 次广播响应（1-based），之后自动解绑。
 *
 * 用法：
 *   .elementAt(3)   // 忽略前 2 次，第 3 次广播后解绑
 *
 * 等价于 .skip(n-1).take(1)；
 * 适合"只响应第一次确认"、"第三次才触发"等场景。
 */
@property (nonatomic, readonly) JHBinderCountBlock elementAt;


// MARK: - v1.8 新增操作符

/**
 * 【format】格式化字符串语法糖，是 transform 的高频特化。
 *
 * 支持的格式：
 *   .format(@"¥%.2f")     // 浮点数 → "¥12.50"（NSNumber float/double 自动用 doubleValue）
 *   .format(@"%lld 次")   // 整数   → "42 次"（NSNumber 整数类型自动用 longLongValue）
 *   .format(@"共 %@ 件")  // 任意值 → 用对象的 -description（最安全，推荐）
 *
 * 规则：
 *   - 格式串含 %@ → 直接传入对象
 *   - 值是 NSNumber float/double → 传 doubleValue
 *   - 值是 NSNumber 整数 → 传 longLongValue
 *   - nil / NSNull → 原样透传（不格式化）
 *   - 可与其他 transform 链式组合，format 追加在已有 transformBlock 之后
 */
@property (nonatomic, readonly) JHBinderFormatBlock format;

/**
 * 【notNil】过滤 nil 和 NSNull，只允许有效对象通过。
 *
 * 用法：
 *   .notNil   // 点访问，无括号
 *
 * 等价于：.filter(^BOOL(id __unused o, id v){ return v && v != [NSNull null]; })
 * 可与 required 组合：.notNil.required（等价于只用 required）
 */
@property (nonatomic, readonly) JHBinder *notNil;

/**
 * 【required】比 notNil 更严格：额外过滤空字符串。
 *
 * 用法：
 *   .required   // 点访问，无括号
 *
 * nil / NSNull / @"" 均不通过；非字符串类型只做 nil / NSNull 检查。
 * 适用于表单必填项校验、搜索关键词非空校验等场景。
 */
@property (nonatomic, readonly) JHBinder *required;

/**
 * 【pausable】动态开关：signal 当前值为 true 时广播通过，false 时整条链静默。
 *
 * 用法：
 *   JHBinder *loginSignal = JHBinder.listen(session, @"isLoggedIn");
 *   JHBinder
 *       .listen(model, @"balance")
 *       .pausable(loginSignal)     // 未登录时 balance 变化不触发 UI 更新
 *       .receive(label, @"text")
 *       .store(self.bindings);
 *
 * - signal 由 pausable 强持有，无需单独 store
 * - signal 首次有效值（true）出现后，链自动恢复广播
 * - 暂停期间积累的值会丢弃（不缓冲），恢复后只有新广播才会触发
 */
@property (nonatomic, readonly) JHBinderWithLatestFromBlock pausable;

/**
 * 【rebindTo:keyPath:】热替换第一个 KVO 监听节点的 target，不重建链。
 *
 * 用法（典型 Cell 复用场景）：
 *   // cellForRow — 首次建链（或 prepareForReuse 后）
 *   self.nameBinder = JHBinder.listen(model, @"name").receive(self.nameLabel, @"text");
 *   [self.nameBinder store:self.bindings];
 *
 *   // updateWithModel: — Cell 复用时只换 target
 *   [self.nameBinder rebindTo:newModel keyPath:@"name"];
 *
 * 调用后立即 fire 一次，UI 立刻同步到新 target 的当前值。
 * 只替换第一个 KVO listen 节点；UIControl target-action 节点不受影响。
 */
- (void)rebindTo:(nullable id)newTarget keyPath:(NSString *)newKeyPath;


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
