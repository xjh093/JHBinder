//
//  V13DemoView.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/26/26.
//

#import "V13DemoView.h"

@interface V13DemoView ()
@property (nonatomic, strong, readwrite) UITextField *filterField;
@property (nonatomic, strong, readwrite) UILabel     *shortLabel;
@property (nonatomic, strong, readwrite) UILabel     *longLabel;
@property (nonatomic, strong, readwrite) UITextField *firstNameField;
@property (nonatomic, strong, readwrite) UITextField *lastNameField;
@property (nonatomic, strong, readwrite) UILabel     *fullNameLabel;
@property (nonatomic, strong, readwrite) UIButton    *submitButton;
@end

@implementation V13DemoView

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

    CGFloat pad = 16;
    CGFloat w   = self.bounds.size.width - pad * 2;
    CGFloat top = 12;
    CGFloat fh  = 36;
    CGFloat lh  = 36;
    CGFloat th  = 20;
    CGFloat gap = 24;

    // ── Section 1: nodeMap + nodeFilter ──────────────────────────
    [sv addSubview:[self p_tipLabel:
        @"① nodeMap + nodeFilter — 同一源分流到不同节点（独立 map/filter）"
        frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;

    [sv addSubview:[self p_hintLabel:
        @"输入文本：长度 < 5 → 💬短文本区，长度 ≥ 5 → 📝长文本区"
        frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _filterField = [self p_field:@"输入文字，观察下方分流效果" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_filterField];
    top += fh + 8;

    // 两个分流 label 并排
    CGFloat halfW = (w - 8) / 2;
    _shortLabel = [self p_valueLabel:@"💬 短文本区" frame:CGRectMake(pad, top, halfW, lh)];
    _shortLabel.backgroundColor = [[UIColor systemOrangeColor] colorWithAlphaComponent:0.1];
    [sv addSubview:_shortLabel];

    _longLabel = [self p_valueLabel:@"📝 长文本区" frame:CGRectMake(pad + halfW + 8, top, halfW, lh)];
    _longLabel.backgroundColor = [[UIColor systemGreenColor] colorWithAlphaComponent:0.1];
    [sv addSubview:_longLabel];
    top += lh + 6;

    [sv addSubview:[self p_hintLabel:
        @"每个节点独立过滤：不满足条件的节点跳过，不影响另一个节点"
        frame:CGRectMake(pad, top, w, th)]];
    top += th + gap;

    // ── 分割线 ────────────────────────────────────────────────────
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(pad, top, w, 0.5)];
    line.backgroundColor = [UIColor separatorColor];
    [sv addSubview:line];
    top += 0.5 + gap;

    // ── Section 2: combineLatest ──────────────────────────────────
    [sv addSubview:[self p_tipLabel:
        @"② combineLatest — 多源合并，任意源变化时重新合并"
        frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;

    [sv addSubview:[self p_hintLabel:
        @"两个输入框都至少填写一次后，姓名才开始合并；按钮 enabled 需两者均非空"
        frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;

    _firstNameField = [self p_field:@"First Name（名）" frame:CGRectMake(pad, top, halfW, fh)];
    [sv addSubview:_firstNameField];

    _lastNameField = [self p_field:@"Last Name（姓）" frame:CGRectMake(pad + halfW + 8, top, halfW, fh)];
    [sv addSubview:_lastNameField];
    top += fh + 8;

    _fullNameLabel = [self p_valueLabel:@"（等待两个字段都输入…）" frame:CGRectMake(pad, top, w, lh)];
    _fullNameLabel.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.08];
    [sv addSubview:_fullNameLabel];
    top += lh + 8;

    _submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _submitButton.frame = CGRectMake(pad, top, w, 44);
    [_submitButton setTitle:@"提交（名字非空才可点击）" forState:UIControlStateNormal];
    _submitButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    _submitButton.backgroundColor = [UIColor systemBlueColor];
    [_submitButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [_submitButton setTitleColor:[UIColor.whiteColor colorWithAlphaComponent:0.4] forState:UIControlStateDisabled];
    _submitButton.layer.cornerRadius = 10;
    _submitButton.clipsToBounds = YES;
    _submitButton.enabled = NO;
    [sv addSubview:_submitButton];
    top += 44 + 20;

    sv.contentSize = CGSizeMake(self.bounds.size.width, top);
}

// MARK: - 私有工厂

- (UILabel *)p_tipLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *lb = [[UILabel alloc] initWithFrame:frame];
    lb.text = text;
    lb.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    lb.textColor = [UIColor secondaryLabelColor];
    lb.numberOfLines = 2;
    return lb;
}

- (UILabel *)p_hintLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *lb = [[UILabel alloc] initWithFrame:frame];
    lb.text = text;
    lb.font = [UIFont systemFontOfSize:11];
    lb.textColor = [UIColor tertiaryLabelColor];
    lb.numberOfLines = 2;
    return lb;
}

- (UILabel *)p_valueLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *lb = [[UILabel alloc] initWithFrame:frame];
    lb.text = text;
    lb.font = [UIFont systemFontOfSize:14];
    lb.textColor = [UIColor labelColor];
    lb.layer.cornerRadius = 8;
    lb.layer.borderWidth = 0.5;
    lb.layer.borderColor = [UIColor separatorColor].CGColor;
    lb.clipsToBounds = YES;
    lb.textAlignment = NSTextAlignmentCenter;
    return lb;
}

- (UITextField *)p_field:(NSString *)placeholder frame:(CGRect)frame {
    UITextField *tf = [[UITextField alloc] initWithFrame:frame];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.font = [UIFont systemFontOfSize:14];
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    tf.returnKeyType = UIReturnKeyDone;
    return tf;
}

@end
