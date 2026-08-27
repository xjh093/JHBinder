//
//  V14DemoView.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//

#import "V14DemoView.h"

@interface V14DemoView ()
@property (nonatomic, strong, readwrite) UITextField *defaultField;
@property (nonatomic, strong, readwrite) UILabel     *defaultResultLabel;
@property (nonatomic, strong, readwrite) UIButton    *resetButton;
@property (nonatomic, strong, readwrite) UITextField *skipField;
@property (nonatomic, strong, readwrite) UILabel     *skipResultLabel;
@property (nonatomic, strong, readwrite) UILabel     *skipHintLabel;
@property (nonatomic, strong, readwrite) UITextField *takeField;
@property (nonatomic, strong, readwrite) UILabel     *takeResultLabel;
@property (nonatomic, strong, readwrite) UILabel     *takeCountLabel;
@property (nonatomic, strong, readwrite) UITextField *throttleField;
@property (nonatomic, strong, readwrite) UILabel     *throttleResultLabel;
@property (nonatomic, strong, readwrite) UILabel     *throttleCountLabel;
@property (nonatomic, strong, readwrite) UITextField *throttleTrailingField;
@property (nonatomic, strong, readwrite) UILabel     *throttleTrailingResultLabel;
@property (nonatomic, strong, readwrite) UILabel     *throttleTrailingCountLabel;
@property (nonatomic, strong, readwrite) UITextField *throttleTrailingOnlyField;
@property (nonatomic, strong, readwrite) UILabel     *throttleTrailingOnlyResultLabel;
@property (nonatomic, strong, readwrite) UILabel     *throttleTrailingOnlyCountLabel;
@end

@implementation V14DemoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self p_setupUI]; }
    return self;
}

- (void)p_setupUI {
    self.backgroundColor = [UIColor systemBackgroundColor];

    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:self.bounds];
    sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sv.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self addSubview:sv];

    CGFloat pad  = 16;
    CGFloat w    = self.bounds.size.width - pad * 2;
    CGFloat hw   = (w - 8) / 2;
    CGFloat top  = 12;
    CGFloat fh   = 36;
    CGFloat lh   = 36;
    CGFloat th   = 18;
    CGFloat gap  = 24;

    // ── ① defaultValue ───────────────────────────────────────────
    [sv addSubview:[self p_tip:@"① defaultValue — nil 时显示默认值（配合 fire 演示）"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"点「重置」→ 模型置 nil → label 显示默认文本"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _defaultField = [self p_field:@"输入后 label 实时同步…" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_defaultField];
    top += fh + 6;

    _defaultResultLabel = [self p_valueLabel:@"…" frame:CGRectMake(pad, top, hw, lh)];
    _defaultResultLabel.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.08];
    [sv addSubview:_defaultResultLabel];

    _resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _resetButton.frame = CGRectMake(pad + hw + 8, top, hw, lh);
    [_resetButton setTitle:@"重置（model = nil）" forState:UIControlStateNormal];
    _resetButton.layer.cornerRadius = 8;
    _resetButton.layer.borderWidth = 0.5;
    _resetButton.layer.borderColor = [UIColor systemRedColor].CGColor;
    [_resetButton setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    _resetButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [sv addSubview:_resetButton];
    top += lh + gap;

    // 分割线
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ② skip(N) ────────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"② skip(2) — 跳过前 2 次广播，第 3 次才更新"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"快速输入：前两次变化 label 不动，第三次起才同步"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _skipField = [self p_field:@"输入任意内容" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_skipField];
    top += fh + 6;

    _skipResultLabel = [self p_valueLabel:@"（前 2 次跳过）" frame:CGRectMake(pad, top, hw, lh)];
    [sv addSubview:_skipResultLabel];

    _skipHintLabel = [self p_countLabel:@"已跳过 0/2" frame:CGRectMake(pad + hw + 8, top, hw, lh)];
    [sv addSubview:_skipHintLabel];
    top += lh + gap;

    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ③ take(3) ────────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"③ take(3) — 只广播 3 次，之后自动解绑"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"输入 4 次以上：第 4 次起 label 不再变化（已解绑）"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _takeField = [self p_field:@"最多更新 3 次后冻结" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_takeField];
    top += fh + 6;

    _takeResultLabel = [self p_valueLabel:@"（等待输入）" frame:CGRectMake(pad, top, hw, lh)];
    [sv addSubview:_takeResultLabel];

    _takeCountLabel = [self p_countLabel:@"剩余 3 次" frame:CGRectMake(pad + hw + 8, top, hw, lh)];
    [sv addSubview:_takeCountLabel];
    top += lh + gap;

    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ④ throttle(1.0) ──────────────────────────────────────────
    [sv addSubview:[self p_tip:@"④ throttle(1.0) — 每秒最多广播 1 次（节流）"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"快速连续输入：label 每秒只更新一次，次数远小于按键次数"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _throttleField = [self p_field:@"快速输入，观察广播频率" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_throttleField];
    top += fh + 6;

    _throttleResultLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, hw, lh)];
    [sv addSubview:_throttleResultLabel];

    _throttleCountLabel = [self p_countLabel:@"广播 0 次" frame:CGRectMake(pad + hw + 8, top, hw, lh)];
    [sv addSubview:_throttleCountLabel];
    top += lh + gap;

    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ⑤ throttleTrailing(1.0) ───────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"⑤ throttleTrailing(1.0) — 前沿立即发，窗口结束时补发最后值"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"快输输入：第 1 次立刻广播，1s 后补发最终结果"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _throttleTrailingField = [self p_field:@"快速输入，观察前沿+后沿广播" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_throttleTrailingField];
    top += fh + 6;

    _throttleTrailingResultLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, hw, lh)];
    [sv addSubview:_throttleTrailingResultLabel];

    _throttleTrailingCountLabel = [self p_countLabel:@"广播 0 次" frame:CGRectMake(pad + hw + 8, top, hw, lh)];
    [sv addSubview:_throttleTrailingCountLabel];
    top += lh + gap;

    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ⑥ throttleTrailingOnly(1.0) ──────────────────────────────────────────
    [sv addSubview:[self p_tip:@"⑥ throttleTrailingOnly(1.0) — 窗口结束时发最后一个值"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"快输输入：全部压制，1s 后一次性广播最终结果（计时器不重置）"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _throttleTrailingOnlyField = [self p_field:@"快速输入，观察后沿广播" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_throttleTrailingOnlyField];
    top += fh + 6;

    _throttleTrailingOnlyResultLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, hw, lh)];
    [sv addSubview:_throttleTrailingOnlyResultLabel];

    _throttleTrailingOnlyCountLabel = [self p_countLabel:@"广播 0 次" frame:CGRectMake(pad + hw + 8, top, hw, lh)];
    [sv addSubview:_throttleTrailingOnlyCountLabel];
    top += lh + 20;

    sv.contentSize = CGSizeMake(self.bounds.size.width, top);
}

// MARK: - 工厂

- (UILabel *)p_tip:(NSString *)t frame:(CGRect)f {
    UILabel *lb = [[UILabel alloc] initWithFrame:f];
    lb.text = t; lb.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    lb.textColor = [UIColor secondaryLabelColor]; lb.numberOfLines = 2;
    return lb;
}
- (UILabel *)p_hint:(NSString *)t frame:(CGRect)f {
    UILabel *lb = [[UILabel alloc] initWithFrame:f];
    lb.text = t; lb.font = [UIFont systemFontOfSize:11];
    lb.textColor = [UIColor tertiaryLabelColor]; lb.numberOfLines = 2;
    return lb;
}
- (UILabel *)p_valueLabel:(NSString *)t frame:(CGRect)f {
    UILabel *lb = [[UILabel alloc] initWithFrame:f];
    lb.text = t; lb.font = [UIFont systemFontOfSize:14];
    lb.textColor = [UIColor labelColor]; lb.textAlignment = NSTextAlignmentCenter;
    lb.layer.cornerRadius = 8; lb.layer.borderWidth = 0.5;
    lb.layer.borderColor = [UIColor separatorColor].CGColor; lb.clipsToBounds = YES;
    return lb;
}
- (UILabel *)p_countLabel:(NSString *)t frame:(CGRect)f {
    UILabel *lb = [[UILabel alloc] initWithFrame:f];
    lb.text = t; lb.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    lb.textColor = [UIColor tertiaryLabelColor]; lb.textAlignment = NSTextAlignmentRight;
    lb.numberOfLines = 2;
    return lb;
}
- (UITextField *)p_field:(NSString *)ph frame:(CGRect)f {
    UITextField *tf = [[UITextField alloc] initWithFrame:f];
    tf.placeholder = ph; tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.font = [UIFont systemFontOfSize:14]; tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    tf.returnKeyType = UIReturnKeyDone;
    return tf;
}
- (UIView *)p_line:(CGRect)f {
    UIView *v = [[UIView alloc] initWithFrame:f];
    v.backgroundColor = [UIColor separatorColor];
    return v;
}

@end
