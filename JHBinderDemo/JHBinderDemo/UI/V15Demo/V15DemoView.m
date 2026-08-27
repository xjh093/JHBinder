//
//  V15DemoView.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//

#import "V15DemoView.h"

@interface V15DemoView ()
@property (nonatomic, strong, readwrite) UITextField *transformField;
@property (nonatomic, strong, readwrite) UILabel     *transformResultLabel;
@property (nonatomic, strong, readwrite) UITextField *scanField;
@property (nonatomic, strong, readwrite) UILabel     *scanResultLabel;
@property (nonatomic, strong, readwrite) UILabel     *scanHistoryLabel;
@property (nonatomic, strong, readwrite) UITextField *withPreviousField;
@property (nonatomic, strong, readwrite) UILabel     *withPreviousResultLabel;
@property (nonatomic, strong, readwrite) UITextField *biMapField;
@property (nonatomic, strong, readwrite) UILabel     *biMapValueLabel;
@property (nonatomic, strong, readwrite) UIButton    *biMapIncrButton;
@property (nonatomic, strong, readwrite) UIButton    *biMapDecrButton;
@end

@implementation V15DemoView

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

    CGFloat pad = 16;
    CGFloat w   = self.bounds.size.width - pad * 2;
    CGFloat top = 12;
    CGFloat fh  = 36;
    CGFloat lh  = 36;
    CGFloat th  = 18;
    CGFloat gap = 24;

    // ── ① transform ──────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"① transform — 链级值变换（统一转大写）"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"输入任意字母 → result label 显示全大写版本"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _transformField = [self p_field:@"输入小写字母…" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_transformField];
    top += fh + 6;

    _transformResultLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, w, lh)];
    _transformResultLabel.backgroundColor = [[UIColor systemGreenColor] colorWithAlphaComponent:0.07];
    [sv addSubview:_transformResultLabel];
    top += lh + gap;

    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ② scan ───────────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"② scan — 累加器（每次按键计数 +1）"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"输入任意内容 → observe 收到的是 scan 累加后的计数值，不是原始字符串"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _scanField = [self p_field:@"快速输入，观察计数器如何累加" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_scanField];
    top += fh + 6;

    _scanResultLabel = [self p_valueLabel:@"已触发 0 次" frame:CGRectMake(pad, top, w, lh)];
    _scanResultLabel.backgroundColor = [[UIColor systemOrangeColor] colorWithAlphaComponent:0.07];
    [sv addSubview:_scanResultLabel];
    top += lh + 6;

    _scanHistoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(pad, top, w, th * 2)];
    _scanHistoryLabel.text = @"计数轨迹：";
    _scanHistoryLabel.font = [UIFont systemFontOfSize:11];
    _scanHistoryLabel.textColor = [UIColor tertiaryLabelColor];
    _scanHistoryLabel.numberOfLines = 3;
    [sv addSubview:_scanHistoryLabel];
    top += th * 2 + gap;

    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ③ withPrevious ───────────────────────────────────────────
    [sv addSubview:[self p_tip:@"③ withPrevious — 双值打包（展示前后变化）"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"每次广播接收节点收到 @[prevValue, newValue]，显示\"从X变为Y\""
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _withPreviousField = [self p_field:@"输入任意内容观察变化" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_withPreviousField];
    top += fh + 6;

    _withPreviousResultLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, w, lh * 1.5)];
    _withPreviousResultLabel.numberOfLines = 2;
    _withPreviousResultLabel.backgroundColor = [[UIColor systemPurpleColor] colorWithAlphaComponent:0.07];
    [sv addSubview:_withPreviousResultLabel];
    top += lh * 1.5 + gap;

    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ④ biMap ──────────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"④ biMap — 双向映射（NSNumber ↔ NSString）"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"输入数字回车 → backward 转 NSNumber；点 ±1 → forward 转字符串→textField"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _biMapField = [self p_field:@"输入整数回车确认" frame:CGRectMake(pad, top, w, fh)];
    _biMapField.keyboardType = UIKeyboardTypeNumberPad;
    [sv addSubview:_biMapField];
    top += fh + 6;

    _biMapValueLabel = [self p_valueLabel:@"—" frame:CGRectMake(pad, top, w, lh)];
    _biMapValueLabel.backgroundColor = [[UIColor systemTealColor] colorWithAlphaComponent:0.07];
    [sv addSubview:_biMapValueLabel];
    top += lh + 8;

    CGFloat bw = (w - 8) / 2;
    _biMapDecrButton = [self p_actionButton:@"−  1" frame:CGRectMake(pad, top, bw, lh)];
    [sv addSubview:_biMapDecrButton];
    _biMapIncrButton = [self p_actionButton:@"+  1" frame:CGRectMake(pad + bw + 8, top, bw, lh)];
    [sv addSubview:_biMapIncrButton];
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
    lb.numberOfLines = 0;
    return lb;
}
- (UITextField *)p_field:(NSString *)ph frame:(CGRect)f {
    UITextField *tf = [[UITextField alloc] initWithFrame:f];
    tf.placeholder = ph; tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.font = [UIFont systemFontOfSize:14]; tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    tf.returnKeyType = UIReturnKeyDone; tf.autocorrectionType = UITextAutocorrectionTypeNo;
    return tf;
}
- (UIView *)p_line:(CGRect)f {
    UIView *v = [[UIView alloc] initWithFrame:f];
    v.backgroundColor = [UIColor separatorColor];
    return v;
}
- (UIButton *)p_actionButton:(NSString *)title frame:(CGRect)f {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = f;
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    btn.layer.cornerRadius = 8;
    btn.layer.borderWidth = 0.5;
    btn.layer.borderColor = [UIColor systemBlueColor].CGColor;
    return btn;
}

@end
