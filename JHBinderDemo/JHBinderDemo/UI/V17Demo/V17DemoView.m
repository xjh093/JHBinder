//
//  V17DemoView.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//

#import "V17DemoView.h"

@interface V17DemoView ()
@property (nonatomic, strong, readwrite) UILabel      *tickerLabel;
@property (nonatomic, strong, readwrite) UIButton     *stopButton;
@property (nonatomic, strong, readwrite) UIButton     *pluckRequestButton;
@property (nonatomic, strong, readwrite) UILabel      *pluckResultLabel;
@property (nonatomic, strong, readwrite) UIButton     *bufferCountButton;
@property (nonatomic, strong, readwrite) UILabel      *bufferCountLabel;
@property (nonatomic, strong, readwrite) UILabel      *bufferCountHintLabel;
@property (nonatomic, strong, readwrite) UITextField  *bufferTimeField;
@property (nonatomic, strong, readwrite) UILabel      *bufferTimeLabel;
@property (nonatomic, strong, readwrite) UIButton     *timeoutResetButton;
@property (nonatomic, strong, readwrite) UILabel      *timeoutStatusLabel;
@property (nonatomic, strong, readwrite) UIButton     *rapidButton;
@property (nonatomic, strong, readwrite) UILabel      *sampleLabel;
@property (nonatomic, strong, readwrite) UILabel      *sampleRawLabel;
@property (nonatomic, strong, readwrite) UITextField  *combineFieldA;
@property (nonatomic, strong, readwrite) UITextField  *combineFieldB;
@property (nonatomic, strong, readwrite) UILabel      *combineResultLabel;
@property (nonatomic, strong, readwrite) UIButton     *elementAtButton;
@property (nonatomic, strong, readwrite) UILabel      *elementAtLabel;
@end

@implementation V17DemoView

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
    CGFloat fh = 40, lh = 32, th = 18, bh = 40, gap = 16;
    CGFloat top = 20;

    // ── ① interval + takeUntil ───────────────────────────────────
    [sv addSubview:[self p_tip:@"① interval + takeUntil — 定时器源 + 自动停止"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"interval(1s) 每秒广播；点\"停止\"后 takeUntil 解绑整条链"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _tickerLabel = [self p_valueLabel:@"等待第一次 tick…"
                                frame:CGRectMake(pad, top, w - 90, lh)];
    [sv addSubview:_tickerLabel];
    _stopButton = [self p_button:@"停止" frame:CGRectMake(pad + w - 80, top, 80, lh)];
    [sv addSubview:_stopButton];
    top += lh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ② pluck ──────────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"② pluck — 从嵌套对象中 KVC 提取子属性"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"点击后 model.apiResponse 设置嵌套字典；pluck(@\"user.name\") 提取名称"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _pluckRequestButton = [self p_button:@"模拟 API 返回" frame:CGRectMake(pad, top, 160, bh)];
    [sv addSubview:_pluckRequestButton];
    _pluckResultLabel = [self p_valueLabel:@"提取结果：（未触发）"
                                     frame:CGRectMake(pad + 168, top, w - 168, bh)];
    [sv addSubview:_pluckResultLabel];
    top += bh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ③ bufferCount(3) ─────────────────────────────────────────
    [sv addSubview:[self p_tip:@"③ bufferCount(3) — 积累 3 个值后打包广播"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"每次点\"入队\"，攒够 3 个后向下广播 @[v1,v2,v3]"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _bufferCountButton = [self p_button:@"入队（+1）" frame:CGRectMake(pad, top, 130, bh)];
    [sv addSubview:_bufferCountButton];
    _bufferCountHintLabel = [self p_valueLabel:@"已入队：0/3"
                                         frame:CGRectMake(pad + 138, top, w - 138, bh)];
    [sv addSubview:_bufferCountHintLabel];
    top += bh + 6;
    _bufferCountLabel = [self p_multilineLabel:@"批次结果：（等待满 3 个）"
                                          frame:CGRectMake(pad, top, w, lh * 2 + 4)];
    [sv addSubview:_bufferCountLabel];
    top += lh * 2 + 4 + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ④ bufferTime(2s) ─────────────────────────────────────────
    [sv addSubview:[self p_tip:@"④ bufferTime(2s) — 2 秒内的变化打包广播"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"快速连续输入文本，每 2 秒将本段时间内所有变化合并为数组"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _bufferTimeField = [self p_field:@"快速输入…" frame:CGRectMake(pad, top, w, fh)];
    [sv addSubview:_bufferTimeField];
    top += fh + 6;
    _bufferTimeLabel = [self p_multilineLabel:@"批次结果：（等待 2s）"
                                        frame:CGRectMake(pad, top, w, lh * 2 + 4)];
    [sv addSubview:_bufferTimeLabel];
    top += lh * 2 + 4 + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ⑤ timeout(4s) ────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"⑤ timeout(4s) — 4 秒无操作自动触发 fallback"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"点\"重置计时\"更新状态；4 秒不操作则显示超时提示"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _timeoutResetButton = [self p_button:@"重置计时" frame:CGRectMake(pad, top, 130, bh)];
    [sv addSubview:_timeoutResetButton];
    _timeoutStatusLabel = [self p_valueLabel:@"等待首次操作（4s 超时）…"
                                       frame:CGRectMake(pad + 138, top, w - 138, bh)];
    [sv addSubview:_timeoutStatusLabel];
    top += bh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ⑥ sample(1s) ─────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"⑥ sample(1s) — 高频源，每秒采样一次推送"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"快速点\"快速递增\"，raw 显示真实频率；sample 标签每秒最多更新一次"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _rapidButton = [self p_button:@"快速递增" frame:CGRectMake(pad, top, 130, bh)];
    [sv addSubview:_rapidButton];
    CGFloat halfW = (w - 138 - 8) / 2;
    _sampleRawLabel = [self p_valueLabel:@"raw: 0"
                                   frame:CGRectMake(pad + 138, top, halfW, bh)];
    [sv addSubview:_sampleRawLabel];
    _sampleLabel = [self p_valueLabel:@"sample: —"
                                frame:CGRectMake(pad + 138 + halfW + 8, top, halfW, bh)];
    [sv addSubview:_sampleLabel];
    top += bh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ⑦ combine ────────────────────────────────────────────────
    [sv addSubview:[self p_tip:@"⑦ combine — combineLatest 链式实例方法版"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"两个输入框任意变化 → combine 合并 → result 更新"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    CGFloat fieldW = (w - 8) / 2;
    _combineFieldA = [self p_field:@"A 输入…" frame:CGRectMake(pad, top, fieldW, fh)];
    [sv addSubview:_combineFieldA];
    _combineFieldB = [self p_field:@"B 输入…" frame:CGRectMake(pad + fieldW + 8, top, fieldW, fh)];
    [sv addSubview:_combineFieldB];
    top += fh + 6;
    _combineResultLabel = [self p_valueLabel:@"combine 结果：（等待两路均有值）"
                                       frame:CGRectMake(pad, top, w, lh)];
    [sv addSubview:_combineResultLabel];
    top += lh + gap;
    [sv addSubview:[self p_line:CGRectMake(pad, top, w, 0.5)]];
    top += 0.5 + gap;

    // ── ⑧ elementAt(3) ───────────────────────────────────────────
    [sv addSubview:[self p_tip:@"⑧ elementAt(3) — 只对第 3 次广播响应后自动解绑"
                         frame:CGRectMake(pad, top, w, th)]];
    top += th + 4;
    [sv addSubview:[self p_hint:@"多次点击按钮，只有第 3 次才更新标签；之后按钮失效"
                          frame:CGRectMake(pad, top, w, th)]];
    top += th + 6;
    _elementAtButton = [self p_button:@"点我（第 3 次有效）" frame:CGRectMake(pad, top, 200, bh)];
    [sv addSubview:_elementAtButton];
    _elementAtLabel = [self p_valueLabel:@"等待第 3 次…"
                                   frame:CGRectMake(pad + 208, top, w - 208, bh)];
    [sv addSubview:_elementAtLabel];
    top += bh + 40;

    sv.contentSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width, top);
}

// MARK: - 工厂辅助

- (UILabel *)p_tip:(NSString *)text frame:(CGRect)frame {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.font = [UIFont boldSystemFontOfSize:13];
    l.textColor = [UIColor secondaryLabelColor];
    return l;
}

- (UILabel *)p_hint:(NSString *)text frame:(CGRect)frame {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.font = [UIFont systemFontOfSize:11];
    l.textColor = [UIColor tertiaryLabelColor];
    l.numberOfLines = 2;
    return l;
}

- (UILabel *)p_valueLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.font = [UIFont systemFontOfSize:14];
    l.textColor = [UIColor labelColor];
    l.adjustsFontSizeToFitWidth = YES;
    l.minimumScaleFactor = 0.7;
    return l;
}

- (UILabel *)p_multilineLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.font = [UIFont systemFontOfSize:13];
    l.textColor = [UIColor labelColor];
    l.numberOfLines = 0;
    l.lineBreakMode = NSLineBreakByWordWrapping;
    return l;
}

- (UITextField *)p_field:(NSString *)placeholder frame:(CGRect)frame {
    UITextField *tf = [[UITextField alloc] initWithFrame:frame];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.font = [UIFont systemFontOfSize:14];
    tf.backgroundColor = [UIColor systemBackgroundColor];
    return tf;
}

- (UIButton *)p_button:(NSString *)title frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14];
    btn.backgroundColor = [UIColor systemBlueColor];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.layer.cornerRadius = 8;
    btn.layer.masksToBounds = YES;
    return btn;
}

- (UIView *)p_line:(CGRect)frame {
    UIView *v = [[UIView alloc] initWithFrame:frame];
    v.backgroundColor = [UIColor separatorColor];
    return v;
}

@end
