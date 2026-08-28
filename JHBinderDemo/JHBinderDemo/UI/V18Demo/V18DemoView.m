//
//  V18DemoView.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/28/26.
//

#import "V18DemoView.h"

#define kPadding  16.0
#define kLabelH   32.0
#define kItemGap  10.0
#define kSectionGap 20.0
#define kWidth    ([UIScreen mainScreen].bounds.size.width - kPadding * 2)

@implementation V18DemoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemGroupedBackgroundColor];
        [self p_buildUI];
    }
    return self;
}

- (void)p_buildUI {
    CGFloat x = kPadding;
    CGFloat y = kPadding;

    // ─────────────────────────────────────
    // ① format
    // ─────────────────────────────────────
    y = [self p_addSectionTitle:@"① format  (¥%.2f / 共 %@ 件)" y:y];

    _priceSlider = [[UISlider alloc] initWithFrame:CGRectMake(x, y, kWidth, 30)];
    _priceSlider.minimumValue = 0; _priceSlider.maximumValue = 999.99; _priceSlider.value = 128.0;
    [self addSubview:_priceSlider]; y += 30 + kItemGap;

    _priceLabel = [self p_labelAtY:y text:@"¥128.00" bg:[UIColor systemBlueColor]];
    y += kLabelH + kItemGap;

    _countStepper = [[UIStepper alloc] initWithFrame:CGRectMake(x, y, 140, 30)];
    _countStepper.minimumValue = 0; _countStepper.maximumValue = 99; _countStepper.value = 1;
    [self addSubview:_countStepper]; y += 30 + kItemGap;

    _countLabel = [self p_labelAtY:y text:@"共 1 件" bg:[UIColor systemBlueColor]];
    y += kLabelH + kSectionGap;

    // ─────────────────────────────────────
    // ② notNil
    // ─────────────────────────────────────
    y = [self p_addSectionTitle:@"② notNil  (nil / NSNull 被屏蔽)" y:y];

    CGFloat bw = (kWidth - kItemGap * 2) / 3.0;
    _notNilNilButton   = [self p_buttonAtX:x y:y w:bw title:@"设为 nil"   color:[UIColor systemGrayColor]];
    _notNilNullButton  = [self p_buttonAtX:x + bw + kItemGap y:y w:bw title:@"设为 NSNull" color:[UIColor systemGrayColor]];
    _notNilValueButton = [self p_buttonAtX:x + (bw + kItemGap) * 2 y:y w:bw title:@"有效值" color:[UIColor systemGreenColor]];
    y += 36 + kItemGap;

    _notNilResultLabel = [self p_labelAtY:y text:@"（等待有效值）" bg:[UIColor systemTealColor]];
    y += kLabelH + kSectionGap;

    // ─────────────────────────────────────
    // ③ required
    // ─────────────────────────────────────
    y = [self p_addSectionTitle:@"③ required  (nil + 空字符串被屏蔽)" y:y];

    _requiredField = [[UITextField alloc] initWithFrame:CGRectMake(x, y, kWidth, 36)];
    _requiredField.borderStyle = UITextBorderStyleRoundedRect;
    _requiredField.placeholder = @"输入非空内容才会更新下方标签";
    [self addSubview:_requiredField]; y += 36 + kItemGap;

    _requiredLabel = [self p_labelAtY:y text:@"（等待非空输入）" bg:[UIColor systemOrangeColor]];
    y += kLabelH + kSectionGap;

    // ─────────────────────────────────────
    // ④ pausable
    // ─────────────────────────────────────
    y = [self p_addSectionTitle:@"④ pausable  (未登录时通道关闭)" y:y];

    _loginToggleButton = [self p_buttonAtX:x y:y w:kWidth title:@"▶ 点击登录" color:[UIColor systemGrayColor]];
    y += 36 + kItemGap;
    _loginStateLabel   = [self p_labelAtY:y text:@"未登录" bg:[UIColor systemGrayColor]];
    y += kLabelH + kItemGap;

    _pausableField = [[UITextField alloc] initWithFrame:CGRectMake(x, y, kWidth, 36)];
    _pausableField.borderStyle = UITextBorderStyleRoundedRect;
    _pausableField.placeholder = @"输入内容（只有登录后才更新下方标签）";
    [self addSubview:_pausableField]; y += 36 + kItemGap;

    _pausableResultLabel = [self p_labelAtY:y text:@"（未登录，通道关闭）" bg:[UIColor systemPurpleColor]];
    y += kLabelH + kSectionGap;

    // ─────────────────────────────────────
    // ⑤ rebind
    // ─────────────────────────────────────
    y = [self p_addSectionTitle:@"⑤ rebindTo:keyPath:  (热替换 target)" y:y];

    CGFloat bw2 = (kWidth - kItemGap) / 2.0;
    _rebindToAButton    = [self p_buttonAtX:x y:y w:bw2 title:@"绑定 cardA" color:[UIColor systemBlueColor]];
    _rebindToBButton    = [self p_buttonAtX:x + bw2 + kItemGap y:y w:bw2 title:@"绑定 cardB" color:[UIColor systemIndigoColor]];
    y += 36 + kItemGap;

    _rebindCardLabel    = [self p_labelAtY:y text:@"—" bg:[UIColor systemBrownColor]];
    y += kLabelH + kItemGap;

    _rebindUpdateButton = [self p_buttonAtX:x y:y w:kWidth title:@"修改当前 cardName" color:[UIColor systemRedColor]];
    y += 36 + kSectionGap;

    // ─────────────────────────────────────
    // 更新 contentSize
    // ─────────────────────────────────────
    self.contentSize = CGSizeMake(CGRectGetWidth(self.bounds), y + kPadding);
}

// MARK: - helpers

- (CGFloat)p_addSectionTitle:(NSString *)title y:(CGFloat)y {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(kPadding, y, kWidth, 20)];
    lbl.text = title;
    lbl.font = [UIFont boldSystemFontOfSize:13];
    lbl.textColor = [UIColor secondaryLabelColor];
    [self addSubview:lbl];
    return y + 20 + kItemGap;
}

- (UILabel *)p_labelAtY:(CGFloat)y text:(NSString *)text bg:(UIColor *)bg {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(kPadding, y, kWidth, kLabelH)];
    lbl.text = text;
    lbl.textColor = [UIColor whiteColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.backgroundColor = bg;
    lbl.layer.cornerRadius = 6;
    lbl.clipsToBounds = YES;
    lbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self addSubview:lbl];
    return lbl;
}

- (UIButton *)p_buttonAtX:(CGFloat)x y:(CGFloat)y w:(CGFloat)w title:(NSString *)title color:(UIColor *)color {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(x, y, w, 36);
    [btn setTitle:title forState:UIControlStateNormal];
    btn.tintColor = [UIColor whiteColor];
    btn.backgroundColor = color;
    btn.layer.cornerRadius = 6;
    btn.clipsToBounds = YES;
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self addSubview:btn];
    return btn;
}

@end
