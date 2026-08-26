# JHBinder
轻量级 KVO + UIControl 数据绑定库（链式 DSL）

---

# 绑定链（Chain）
一条链由若干"节点（Node）"组成，共享同一个广播组（Group）。

链内任意节点感知到值变化，就向组内其余节点广播新值。


---

# Example

## 1、model ↔ textField → syncLabel

```
    __weak __typeof(self) weak = self;

    // 绑定链：
    //   model.text（双向，KVO 监听）
    //     ↔ textField.text（双向，UIControlEventEditingChanged 驱动）
    //     → syncLabel.text（单向接收）
    //     → observe block（值变化时打印日志）
    JHBinder
        .twoWay(self.model, @"text")
        .twoWayUI(self.demoView.textField, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.syncLabel, @"text")
        .observe(@"basic.text.changed", ^(id value) {
            NSLog(@"[BasicDemo] model.text = %@  |  from observe block", weak.model.text);
        })
        .store(self.bindings);
```


## 2、map、filter

```
    __weak __typeof(self) weak = self;

    // 单条绑定链覆盖所有节点：
    //   model.text（双向 KVO）
    //     ↔ textField1（UIControlEventEditingChanged）
    //     ↔ textField2（UIControlEventEditingChanged）
    //     → labelNormal（原始文本）
    //     → labelUpper（转大写，convertBlock）
    //     filter：超过 20 字不更新
    //     observe：实时更新字数统计
    JHBinder
        .twoWay(self.model, @"text")
        .twoWayUI(self.demoView.textField1, @"text", UIControlEventEditingChanged)
        .twoWayUI(self.demoView.textField2, @"text", UIControlEventEditingChanged)
        .receive(self.demoView.labelNormal, @"text")
        .receiveMap(self.demoView.labelUpper, @"text", ^id(NSString *text) {
            return text.uppercaseString;
        })
        .filter(^BOOL(id __unused old, id new) {
            // 超过 20 字截断，返回 NO 则本次广播被丢弃
            NSString *text = (NSString *)new;
            return text.length <= 20;
        })
        .observe(@"textfield.text.changed", ^(id value) {
            NSString *text = (NSString *)value ?: @"";
            weak.demoView.counterLabel.text =
                [NSString stringWithFormat:@"当前字数：%lu / 20", (unsigned long)text.length];
        })
        .store(self.bindings);
```

---

# More detail in Demo :)
