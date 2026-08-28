//
//  V18CellDemoCell.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/28/26.
//

#import "V18CellDemoCell.h"
#import "V18CellDemoItemModel.h"
#import "JHBinderKit.h"

@interface V18CellDemoCell ()
// UI
@property (nonatomic, strong) UILabel  *nameLabel;
@property (nonatomic, strong) UILabel  *countLabel;
@property (nonatomic, strong) UIButton *incrementButton;
// 绑定
@property (nonatomic, strong) NSMutableArray *bindings;
@property (nonatomic, strong) JHBinder       *nameBinder;
@property (nonatomic, strong) JHBinder       *countBinder;
// 当前 Model（弱引用，由 VC 持有数组保证生命周期）
@property (nonatomic, weak)   V18CellDemoItemModel *currentModel;
@end

@implementation V18CellDemoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.bindings = [NSMutableArray array];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self p_buildUI];
    }
    return self;
}

- (void)p_buildUI {
    // nameLabel：左侧，显示 model.name
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_nameLabel];

    // countLabel：居中，显示点击次数
    _countLabel = [[UILabel alloc] init];
    _countLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    _countLabel.textColor = [UIColor systemGrayColor];
    _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_countLabel];

    // incrementButton：右侧，点击累加 tapCount
    _incrementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_incrementButton setTitle:@"  ＋  " forState:UIControlStateNormal];
    _incrementButton.backgroundColor = [UIColor systemBlueColor];
    _incrementButton.tintColor = [UIColor whiteColor];
    _incrementButton.layer.cornerRadius = 6;
    _incrementButton.clipsToBounds = YES;
    _incrementButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_incrementButton addTarget:self action:@selector(p_onIncrement) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_incrementButton];

    [NSLayoutConstraint activateConstraints:@[
        [_nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [_nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_nameLabel.widthAnchor constraintEqualToConstant:120],

        [_countLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.trailingAnchor constant:8],
        [_countLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

        [_incrementButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [_incrementButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_incrementButton.heightAnchor constraintEqualToConstant:30],
    ]];
}

// MARK: - 核心：绑定 / 复用热替换

/**
 * 【与直接赋值的本质区别】
 *
 * ❌ 传统直接赋值（快照，一次性）：
 *    self.nameLabel.text = model.name;
 *    → 之后 model.name 改变 → Cell 不更新，必须调用 reloadData
 *
 * ✅ rebindTo: 建立活的 KVO 链：
 *    [_nameBinder rebindTo:model keyPath:@"name"];
 *    → 之后 model.name 改变 → KVO 立即驱动 nameLabel 更新，无需 reloadData
 *    → 网络推送、倒计时、实时状态等场景下，无需知道 indexPath
 */
- (void)bindToModel:(V18CellDemoItemModel *)model {
    _currentModel = model;

    if (!_nameBinder) {
        // ──────────────────────────────────────────────────────────
        // 首次使用：建立绑定，binder 存入 self.bindings 保持生命周期        
        // 规律：
        //   • 一个 binder = 监听「一个 model 属性」的变化
        //   • 一个属性 → 多个 UI：在同一 binder 上追加 .receive / .receiveMap 节点
        //                          rebindTo: 一次调用，所有 UI 一起更新
        //   • 多个属性 → 各自 UI：需要多少个 binder = 需要响应多少个不同 model 属性
        //
        // 示例：若 name 同时驱动 nameLabel 和 subtitleLabel，只需一个 binder：
        //   JHBinder.listen(model, @"name")
        //       .receive(nameLabel, @"text")
        //       .receiveMap(subtitleLabel, @"text", ^id(id v){ return [@"副标题: " stringByAppendingString:v]; })
        //       .fire();
        //   [_nameBinder rebindTo:newModel keyPath:@"name"];  // 两个 label 同时更新 ✓
        // ──────────────────────────────────────────────────────────

        JHBinder
            .listen(model, @"name")
            .receive(_nameLabel, @"text")
            .fire()
            .assignTo(&_nameBinder)
            .store(self.bindings);

        JHBinder
            .listen(model, @"tapCount")
            .defaultValue(@0)
            .receiveMap(_countLabel, @"text", ^id(id v) {
                return [NSString stringWithFormat:@"点击 %@ 次", v];
            })
            .fire()
            .assignTo(&_countBinder)
            .store(self.bindings);

    } else {
        // ──────────────────────────────────────────────────────────
        // Cell 复用：热替换监听目标，不重建链
        //   - 停止对旧 Model 的 KVO
        //   - 将 listen 节点指向新 Model
        //   - 立即触发一次广播，UI 同步为新 Model 的当前值
        // ──────────────────────────────────────────────────────────
        [_nameBinder  rebindTo:model keyPath:@"name"];
        [_countBinder rebindTo:model keyPath:@"tapCount"];
    }
}

// MARK: - 按钮：累加当前 model 的 tapCount（ObjC 直接赋值，KVO 正常触发）

- (void)p_onIncrement {
    NSNumber *cur = _currentModel.tapCount ?: @0;
    _currentModel.tapCount = @(cur.intValue + 1);
}

@end
