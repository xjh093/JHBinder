//
//  V16DemoView.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//

#import "V16DemoView.h"

@interface V16DemoView ()
@property (nonatomic, strong, readwrite) UITextField *usernameField;
@property (nonatomic, strong, readwrite) UITextField *passwordField;
@property (nonatomic, strong, readwrite) UILabel     *mergeResultLabel;
@property (nonatomic, strong, readwrite) UITextField *keywordField;
@property (nonatomic, strong, readwrite) UITextField *categoryField;
@property (nonatomic, strong, readwrite) UILabel     *wlfResultLabel;
@property (nonatomic, strong, readwrite) UILabel     *startWithLabel;
@property (nonatomic, strong, readwrite) UITextField *tapTextField;
@property (nonatomic, strong, readwrite) UILabel     *tapCountLabel;
@property (nonatomic, strong, readwrite) UIButton    *negateButton;
@property (nonatomic, strong, readwrite) UILabel     *negateStateLabel;
@property (nonatomic, strong, readwrite) UITextField *mapToField;
@property (nonatomic, strong, readwrite) UILabel     *mapToResultLabel;
@property (nonatomic, strong, readwrite) NSArray<UIButton *> *caseButtons;
@property (nonatomic, strong, readwrite) UILabel     *caseResultLabel;
@property (nonatomic, strong, readwrite) UILabel     *caseBroadcastLabel;
@property (nonatomic, strong, readwrite) UIButton    *counterIncrButton;
@property (nonatomic, strong, readwrite) UILabel     *takeWhileLabel;
@property (nonatomic, strong, readwrite) UILabel     *skipWhileLabel;
@end

@implementation V16DemoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemGroupedBackgroundColor];
        self.alwaysBounceVertical = YES;
        [self p_buildUI];
    }
    return self;
}

// MARK: - 布局

- (void)p_buildUI {
    UIScrollView *sv = self;
    CGFloat pad = 16, w = UIScreen.mainScreen.bounds.size.width - pad * 2;
    CGFloat fh = 40, lh = 32, th = 18, gap = 16;
    CGFloat top = 20;

    // ── ① merge ──────────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"① merge — 任一源广播即透传"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"用户名或密码任意改变 → mergeResult 更新（值是最新改变的那个字段）"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _usernameField = [self p_field:@"用户名" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_usernameField];
    top += fh + 6;
    _passwordField = [self p_field:@"密码" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_passwordField];
    top += fh + 6;
    _mergeResultLabel = [self p_valueLabel:@"merge 结果：" frame:CGRectMake(pad, top, w, lh)];
    [sv addSubview:_mergeResultLabel];
    top += lh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ② withLatestFrom ─────────────────────────────────────────
    [sv addSubview:[self p_tip:@"② withLatestFrom — 触发时采样另一路最新值"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"keyword 变化(防抖 0.5s) → 取 category 最新值 → 合并搜索"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _keywordField  = [self p_field:@"搜索关键词（触发源）" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_keywordField];
    top += fh + 6;
    _categoryField = [self p_field:@"分类（采样源，随时可改）" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_categoryField];
    top += fh + 6;
    _wlfResultLabel = [self p_valueLabel:@"搜索结果：" frame:CGRectMake(pad, top, w, lh)];
    [sv addSubview:_wlfResultLabel];
    top += lh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ③ startWith ──────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"③ startWith — 绑定后立即广播指定初始值"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"初始显示「加载中…」，model.statusText 变化后实时更新"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _startWithLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, w, lh)];
    _startWithLabel.backgroundColor = [[UIColor systemGreenColor] colorWithAlphaComponent:0.08];
    [sv addSubview:_startWithLabel];
    top += lh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ④ tap ────────────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"④ tap — 内联副作用，不消费值"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"每次输入触发 tap 计数 +1；receive 节点收到的仍是原始文本"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _tapTextField = [self p_field:@"随意输入" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_tapTextField];
    top += fh + 6;
    _tapCountLabel = [self p_valueLabel:@"tap 副作用计数：0 次" frame:CGRectMake(pad, top, w, lh)];
    [sv addSubview:_tapCountLabel];
    top += lh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ⑤ negate ─────────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"⑤ negate — 布尔取反"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"isLoading=YES → button.enabled=NO；negate 隐式 transform"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _negateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _negateButton.frame = CGRectMake(pad, top, 120, fh);
    [_negateButton setTitle:@"切换 Loading" forState:UIControlStateNormal];
    _negateButton.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.12];
    _negateButton.layer.cornerRadius = 8;
    [sv addSubview:_negateButton];
    _negateStateLabel = [self p_valueLabel:@"isLoading: NO  →  enabled: YES"
                                     frame:CGRectMake(pad + 130, top, w - 130, fh)];
    [sv addSubview:_negateStateLabel];
    top += fh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ⑥ mapTo ──────────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"⑥ mapTo — 恒定映射（任意值→固定值）"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"任意输入 → 接收节点总收到「已更新」，与内容无关"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _mapToField = [self p_field:@"随意输入，结果始终是固定值" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_mapToField];
    top += fh + 6;
    _mapToResultLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, w, lh)];
    [sv addSubview:_mapToResultLabel];
    top += lh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ⑦ distinctWhen ───────────────────────────────────────────
    [sv addSubview:[self p_tip:@"⑦ distinctWhen — 自定义去重（忽略大小写）"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"按预设按鈕设置 model 属性値；apple/Apple/APPLE 大小写不同但视为相同，只有真正不同的内容才触发广播"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    NSArray<NSString *> *caseValues = @[@"apple", @"Apple", @"APPLE", @"banana", @"Banana"];
    NSArray<UIColor *> *caseColors  = @[
        [UIColor systemBlueColor],
        [UIColor systemTealColor],
        [UIColor systemCyanColor],
        [UIColor systemOrangeColor],
        [UIColor systemBrownColor],
    ];
    CGFloat bw = (w - 4 * 6) / 5.0;
    NSMutableArray<UIButton *> *btns = [NSMutableArray array];
    for (NSUInteger i = 0; i < caseValues.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(pad + i * (bw + 6), top, bw, fh);
        [btn setTitle:caseValues[i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        btn.backgroundColor = [caseColors[i] colorWithAlphaComponent:0.12];
        btn.layer.cornerRadius = 6;
        btn.tag = i;
        [sv addSubview:btn];
        [btns addObject:btn];
    }
    _caseButtons = [btns copy];
    top += fh + 6;

    _caseResultLabel = [self p_valueLabel:@"当前属性値：—" frame:CGRectMake(pad, top, w, lh)];
    [sv addSubview:_caseResultLabel];
    top += lh + 4;

    _caseBroadcastLabel = [self p_valueLabel:@"广播次数：0（apple/Apple/APPLE 共触发 1 次）"
                                       frame:CGRectMake(pad, top, w, lh)];
    _caseBroadcastLabel.backgroundColor = [[UIColor systemTealColor] colorWithAlphaComponent:0.08];
    [sv addSubview:_caseBroadcastLabel];
    top += lh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ⑧ takeWhile / skipWhile ──────────────────────────────────
    [sv addSubview:[self p_tip:@"⑧ takeWhile / skipWhile — 条件流控"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"takeWhile: counter < 5 时广播，≥5 自动解绑\nskipWhile: counter < 3 时跳过，≥3 开始广播"
                          frame:CGRectMake(pad, top, w, th * 2)]];
    top += th * 2 + 6;
    _counterIncrButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _counterIncrButton.frame = CGRectMake(pad, top, 100, fh);
    [_counterIncrButton setTitle:@"counter +1" forState:UIControlStateNormal];
    _counterIncrButton.backgroundColor = [[UIColor systemOrangeColor] colorWithAlphaComponent:0.12];
    _counterIncrButton.layer.cornerRadius = 8;
    [sv addSubview:_counterIncrButton];
    top += fh + 6;
    _takeWhileLabel = [self p_valueLabel:@"takeWhile (< 5)：等待广播"
                                   frame:CGRectMake(pad, top, w, lh)];
    _takeWhileLabel.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.07];
    [sv addSubview:_takeWhileLabel];
    top += lh + 6;
    _skipWhileLabel = [self p_valueLabel:@"skipWhile (< 3)：跳过中…"
                                   frame:CGRectMake(pad, top, w, lh)];
    _skipWhileLabel.backgroundColor = [[UIColor systemPurpleColor] colorWithAlphaComponent:0.07];
    [sv addSubview:_skipWhileLabel];
    top += lh + 40;

    sv.contentSize = CGSizeMake(w + pad * 2, top);
}

// MARK: - 辅助工厂

- (UITextField *)p_field:(NSString *)placeholder frame:(CGRect)frame {
    UITextField *f = [[UITextField alloc] initWithFrame:frame];
    f.placeholder = placeholder;
    f.borderStyle = UITextBorderStyleRoundedRect;
    f.font = [UIFont systemFontOfSize:15];
    f.clearButtonMode = UITextFieldViewModeWhileEditing;
    f.returnKeyType = UIReturnKeyDone;
    return f;
}

- (UILabel *)p_tip:(NSString *)text frame:(CGRect)frame {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.font = [UIFont boldSystemFontOfSize:13];
    l.textColor = [UIColor systemBlueColor];
    return l;
}

- (UILabel *)p_hint:(NSString *)text frame:(CGRect)frame {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.font = [UIFont systemFontOfSize:11];
    l.textColor = [UIColor secondaryLabelColor];
    l.numberOfLines = 0;
    return l;
}

- (UILabel *)p_valueLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    l.textColor = [UIColor labelColor];
    l.backgroundColor = [[UIColor systemFillColor] colorWithAlphaComponent:0.5];
    l.layer.cornerRadius = 6;
    l.layer.masksToBounds = YES;
    return l;
}

- (UIView *)p_line:(CGRect)frame {
    UIView *v = [[UIView alloc] initWithFrame:frame];
    v.backgroundColor = [UIColor separatorColor];
    return v;
}

@end
