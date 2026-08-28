v1.8.0

- format(fmt)：格式化字符串语法糖；%@ 传对象，数字类型自动适配 doubleValue/longLongValue
- notNil：属性访问即过滤；屏蔽 nil / NSNull，链只在有效值时广播
- required：比 notNil 更严格；额外屏蔽空字符串（""）和纯空白字符串（trim 后为空），适用于表单必填项
- pausable(signal)：动态开关；signal 当前值为假值（nil / NSNull / @NO / @0）时整条链静默，真值时恢复
- rebindTo:keyPath:：实例方法；热替换第一个 KVO 监听节点的 target，不重建链（Cell 复用场景）
- assignTo(&ref)：链式捕获；将当前 JHBinder 赋值给外部强引用，消除先声明后赋值的样板代码

---

v1.7.0

- +interval(t)：定时器源；每隔 t 秒广播递增计数（类方法）
- takeUntil(signal)：当信号链首次广播时自动解绑整条链
- pluck(keyPath)：从广播对象中用 KVC 提取子属性值
- bufferCount(n)：积累 n 个值后打包为 NSArray 一次性广播
- bufferTime(t)：积累 t 秒内的所有值后打包广播（与 bufferCount 互补）
- timeout(t, fallback)：若 t 秒内无广播，自动发出 fallback 值
- sample(t)：每隔 t 秒取链中最新值推送到接收节点（降频采样）
- combine(other, block)：combineLatest 的实例方法版，链式风格更友好
- elementAt(n)：只对第 n 次广播响应，之后自动解绑

---

v1.6.0

- merge(sources)：多源合并；任一源广播时透传其值，适合"任意字段变化→触发统一回调"
- withLatestFrom(other)：触发+采样；主源触发时取 other 最新值合并为 @[主值, 采样值]
- startWith(value)：绑定建立后立即广播指定初始值（区别于 fire：fire 用当前属性值）
- tap(block)：内联副作用；链中途执行 block 但不消费/修改值，链继续向下传播
- negate()：布尔取反快捷方式；等价于 transform(^id(id v){ return @(![v boolValue]); })
- mapTo(value)：恒定映射；无论源值是什么，接收节点总收到同一个 value
- distinctWhen(comparator)：自定义去重比较器；comparator(old, new) 返回 YES 则视为"相同"跳过
- takeWhile(predicate)：满足条件时广播；predicate 首次返回 NO 时自动解绑整条链
- skipWhile(predicate)：跳过直到条件首次为 NO；之后所有值都通过

---

v1.5.0

- transform(block)：链级全局值变换；广播前对整条链的值统一处理（作用于所有接收节点）
  区别于 nodeMap：nodeMap 只作用于单个节点
- scan(initial, accumulator)：累加器；每次广播基于上次结果和当前值生成新值，适合计数/求和/拼接
- withPrevious()：双值打包；接收节点收到 @[prevValue, newValue]，适合展示变化过程
- biMap(forward, backward)：双向映射；模型→UI 用 forward，UI→模型 用 backward，消除手动两次转换的冷代码

---

v1.4.0

- defaultValue(v)：广播值为 nil / NSNull 时替换为指定默认值
- skip(n)：跳过前 n 次广播，第 n+1 次起正常传递
- take(n)：只广播 n 次，之后自动解绑（n=0 等同于不限次数）
- throttle(t)：节流，窗口期 t 秒内只放行第一次广播（前沿触发，JHThrottleModeLead）
- throttleTrailing(t)：前沿 + 后沿；第一次立即通过，窗口结束时补发最后被压制的值
- throttleTrailingOnly(t)：后沿触发；窗口开始计时，结束时发出最后一个值

---

v1.3.0

- nodeMap(block)：节点级 map，对单个 receive 节点做值转换（不影响其他节点）
- nodeFilter(block)：节点级 filter，对单个 receive 节点过滤（不影响其他节点）
- +combineLatest:combineMap:：多源合并，所有源都有值后触发，合并为一个新值

---

v1.2.0

- distinct()：值未变化时不广播（去重）
- once()：广播一次后自动解绑
- debounce(t)：防抖，最后一次变化 t 秒后才广播
- delay(t)：延迟 t 秒后广播

---

v1.1.0

- fire()：创建绑定后立即触发一次广播，无需等待值变化
- log(@"label")：广播时在控制台打印调试信息

---

v1.0.0

- KVO + UIControl 双向绑定核心（twoWay / twoWayUI）
- 单向监听（listen / listenUI）
- 单向接收（receive / receiveMap）
- 键值观察回调（observe）
- 链级过滤（filter）
- 值转换块（convertBlock / map）
- 绑定组生命周期管理（store / JHBindingManager）
