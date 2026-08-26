//
//  V12DemoView.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/26/26.
//

#import "V12DemoView.h"

@interface V12DemoView ()
@property (nonatomic, strong, readwrite) UILabel     *fireLabel;
@property (nonatomic, strong, readwrite) UITextField *debounceField;
@property (nonatomic, strong, readwrite) UILabel     *debounceResultLabel;
@property (nonatomic, strong, readwrite) UILabel     *debounceCountLabel;
@property (nonatomic, strong, readwrite) UITextField *delayField;
@property (nonatomic, strong, readwrite) UILabel     *delayResultLabel;
@property (nonatomic, strong, readwrite) UITextField *distinctField;
@property (nonatomic, strong, readwrite) UILabel     *distinctResultLabel;
@property (nonatomic, strong, readwrite) UILabel     *distinctCountLabel;
@property (nonatomic, strong, readwrite) UITextField *onceField;
@property (nonatomic, strong, readwrite) UILabel     *onceResultLabel;
@end

@implementation V12DemoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self p_setupUI]; }
    return self;
}

// MARK: - 布局

- (void)p_setupUI {
    self.backgroundColor = [UIColor systemBackgroundColor];

    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:self.bounds];
    sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sv.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self addSubview:sv];

    CGFloat pad  = 16;
    CGFloat w    = self.bounds.size.width - pad * 2;
    CGFloat top  = 12;
    CGFloat fh   = 36;  // field / value-label height
    CGFloat th   = 20;  // tip label height
    CGFloat ch   = 20;  // count label height
    CGFloat gap  = 20;  // section gap

    // ── Section 1: fire() ─────────────────────────────────────────
    [sv addSubview:[self p_tipLabel:@"① fire() — 绑定建立时立即将模型当前值同步到 UI"
                              frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _fireLabel = [self p_valueLabel:@"（等待 fire 同步…）" frame:CGRectMake(pad, top, w, fh)];
    _fireLabel.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.08];
    [sv addSubview:_fireLabel];
    top += fh + gap;

    // ── Section 2: debounce(0.3) + log ────────────────────────────
    [sv addSubview:[self p_tipLabel:@"② debounce(0.3) — 停止输入 0.3s 后广播（log 见控制台）"
                              frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _debounceField = [self p_field:@"输入后停顿 0.3s 才触发广播…" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_debounceField];
    top += fh + 6;

    _debounceResultLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, w * 0.6, fh)];
    [sv addSubview:_debounceResultLabel];

    _debounceCountLabel = [self p_countLabel:@"广播次数：0" frame:CGRectMake(pad + w * 0.65, top, w * 0.35, fh)];
    [sv addSubview:_debounceCountLabel];
    top += fh + gap;

    // ── Section 3: delay(0.5) ─────────────────────────────────────
    [sv addSubview:[self p_tipLabel:@"③ delay(0.5) — 每次触发延迟 0.5s 后更新，快速输入各自延迟"
                              frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _delayField = [self p_field:@"输入后 0.5s 更新下方 label…" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_delayField];
    top += fh + 6;

    _delayResultLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_delayResultLabel];
    top += fh + gap;

    // ── Section 4: distinct() ─────────────────────────────────────
    [sv addSubview:[self p_tipLabel:@"④ distinct() — 输入文字后按 Enter，相同值不重复广播（次数不递增）"
                              frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _distinctField = [self p_field:@"输入内容后按 Enter，重复按 Enter 次数不递增" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_distinctField];
    top += fh + 6;

    _distinctResultLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, w * 0.6, fh)];
    [sv addSubview:_distinctResultLabel];

    _distinctCountLabel = [self p_countLabel:@"广播次数：0" frame:CGRectMake(pad + w * 0.65, top, w * 0.35, fh)];
    [sv addSubview:_distinctCountLabel];
    top += fh + gap;

    // ── Section 5: once() ─────────────────────────────────────────
    [sv addSubview:[self p_tipLabel:@"⑤ once() — 首次广播后自动解绑，label 之后冻结"
                              frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _onceField = [self p_field:@"第一次输入后 label 冻结…" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_onceField];
    top += fh + 6;

    _onceResultLabel = [self p_valueLabel:@"（等待第一次输入）" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_onceResultLabel];
    top += fh + 20;

    sv.contentSize = CGSizeMake(self.bounds.size.width, top);
}

// MARK: - 私有工厂

- (UILabel *)p_tipLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *lb = [[UILabel alloc] initWithFrame:frame];
    lb.text = text;
    lb.font = [UIFont systemFontOfSize:12];
    lb.textColor = [UIColor secondaryLabelColor];
    lb.numberOfLines = 2;
    return lb;
}

- (UILabel *)p_valueLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *lb = [[UILabel alloc] initWithFrame:frame];
    lb.text = text;
    lb.font = [UIFont systemFontOfSize:15];
    lb.textColor = [UIColor labelColor];
    lb.layer.cornerRadius = 6;
    lb.layer.borderWidth = 0.5;
    lb.layer.borderColor = [UIColor separatorColor].CGColor;
    lb.clipsToBounds = YES;
    lb.textAlignment = NSTextAlignmentCenter;
    return lb;
}

- (UILabel *)p_countLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *lb = [[UILabel alloc] initWithFrame:frame];
    lb.text = text;
    lb.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    lb.textColor = [UIColor tertiaryLabelColor];
    lb.textAlignment = NSTextAlignmentRight;
    return lb;
}

- (UITextField *)p_field:(NSString *)placeholder frame:(CGRect)frame {
    UITextField *tf = [[UITextField alloc] initWithFrame:frame];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.font = [UIFont systemFontOfSize:15];
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    tf.returnKeyType = UIReturnKeyDone;
    return tf;
}

@end
