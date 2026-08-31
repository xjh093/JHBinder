//
//  V18CellDemoViewController.m
//  JHBinderDemo
//
//  rebindTo:keyPath: — UITableView Cell 复用演示
//
//  核心问题：直接赋值（cell.label.text = model.name）与 rebind 有什么区别？
//
//  直接赋值 = 快照，一次性写入
//    → 之后 model.name 被修改 → Cell 不更新，必须手动 reloadData
//
//  rebindTo: = 建立活的 KVO 链
//    → 之后 model.name 被修改 → KVO 立即驱动 Cell 更新，无需 reloadData
//    → 数据推送（网络响应、倒计时、实时状态）场景下无需感知 indexPath
//
//  本页演示：
//  ① 滚动列表：Cell 复用时 rebindTo: 被调用，UI 立即刷新为新 model 的值
//  ② "改名" 按钮：修改 model.name，可见 Cell 立即更新（全程不调用 reloadData）
//  ③ Cell 内 [＋] 按钮：直接修改 model.tapCount（ObjC 赋值），KVO 自动更新计数标签
//

#import "V18CellDemoViewController.h"
#import "V18CellDemoCell.h"
#import "V18CellDemoItemModel.h"

static NSString * const kCellID = @"V18CellDemoCell";

@interface V18CellDemoViewController () <UITableViewDataSource>
@property (nonatomic, strong) UITableView                            *tableView;
@property (nonatomic, strong) NSMutableArray<V18CellDemoItemModel *> *items;
@property (nonatomic, strong) UILabel   *statusLabel;   ///< bind/rebind 计数
@property (nonatomic, strong) UILabel   *kvoHintLabel;  ///< "全程未调用 reloadData"
@property (nonatomic, assign) NSInteger  bindCount;
@property (nonatomic, assign) NSInteger  rebindCount;
@property (nonatomic, assign) NSInteger  modelChangeCount;  ///< model 被修改次数
@property (nonatomic, assign) NSInteger  detailExpandCount; ///< 展开详情次数
@end

@implementation V18CellDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"rebindTo: Cell 复用";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.items = [V18CellDemoItemModel makeList:40];
    [self p_buildUI];
}

// MARK: - UI

- (void)p_buildUI {
    // ── 状态栏（bind / rebind 次数）──────────────────────────────
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    _statusLabel.textColor  = [UIColor secondaryLabelColor];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_statusLabel];

    // ── 提示标签 ─────────────────────────────────────────────────
    _kvoHintLabel = [[UILabel alloc] init];
    _kvoHintLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _kvoHintLabel.textColor = [UIColor systemGreenColor];
    _kvoHintLabel.textAlignment = NSTextAlignmentCenter;
    _kvoHintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_kvoHintLabel];

    // ── 按钮行（4个操作按钮）────────────────────────────────────
    UIButton *(^btn)(NSString *, SEL, UIColor *) = ^UIButton *(NSString *title, SEL action, UIColor *color) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:title forState:UIControlStateNormal];
        b.backgroundColor = color;
        b.tintColor = [UIColor whiteColor];
        b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        b.layer.cornerRadius = 6;
        b.clipsToBounds = YES;
        b.translatesAutoresizingMaskIntoConstraints = NO;
        [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        return b;
    };

    UIButton *btnAll      = btn(@"全改",   @selector(p_onRenameAll),    [UIColor systemBlueColor]);
    UIButton *btnOne      = btn(@"改一条", @selector(p_onRenameOne),    [UIColor systemBlueColor]);
    UIButton *btnExpand   = btn(@"展开",   @selector(p_onExpandDetail), [UIColor systemOrangeColor]);
    UIButton *btnCollapse = btn(@"收起",   @selector(p_onCollapseAll),  [UIColor systemGrayColor]);

    UIStackView *buttonRow = [[UIStackView alloc] initWithArrangedSubviews:@[btnAll, btnOne, btnExpand, btnCollapse]];
    buttonRow.axis = UILayoutConstraintAxisHorizontal;
    buttonRow.distribution = UIStackViewDistributionFillEqually;
    buttonRow.spacing = 8;
    buttonRow.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonRow];

    // ── TableView ────────────────────────────────────────────────
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.rowHeight          = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 64;
    [_tableView registerClass:[V18CellDemoCell class] forCellReuseIdentifier:kCellID];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_tableView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_statusLabel.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_statusLabel.heightAnchor constraintEqualToConstant:30],

        [_kvoHintLabel.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor],
        [_kvoHintLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_kvoHintLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_kvoHintLabel.heightAnchor constraintEqualToConstant:24],

        [buttonRow.topAnchor constraintEqualToAnchor:_kvoHintLabel.bottomAnchor constant:8],
        [buttonRow.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [buttonRow.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [buttonRow.heightAnchor constraintEqualToConstant:34],

        [_tableView.topAnchor constraintEqualToAnchor:buttonRow.bottomAnchor constant:8],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self p_updateStatus];
}

- (void)p_updateStatus {
    _statusLabel.text = [NSString stringWithFormat:
        @"建立 %ld | rebind %ld | 改名 %ld | 展开 %ld",
        (long)_bindCount, (long)_rebindCount,
        (long)_modelChangeCount, (long)_detailExpandCount];

    NSInteger totalChanges = _modelChangeCount + _detailExpandCount;
    _kvoHintLabel.text = totalChanges > 0
        ? [NSString stringWithFormat:
            @"✅ 改名 %ld 次未 reload | 展开 %ld 次用 reloadRows:",
            (long)_modelChangeCount, (long)_detailExpandCount]
        : @"← 点击上方按钮：改名（KVO 无 reload）/ 展开（reloadRows:）";
}

// MARK: - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    V18CellDemoCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID
                                                            forIndexPath:indexPath];
    // contentView.tag == 0：首次创建；== 1：复用
    BOOL isFirstBind = (cell.contentView.tag == 0);
    if (isFirstBind) {
        cell.contentView.tag = 1;
        _bindCount++;
    } else {
        _rebindCount++;
    }
    [self p_updateStatus];

    [cell bindToModel:self.items[(NSUInteger)indexPath.row]];
    return cell;
}

// MARK: - 改名（核心演示：只改 model，不调用 reloadData）

/// 修改单条随机 item 的 name
- (void)p_onRenameOne {
    NSUInteger idx = arc4random_uniform((uint32_t)self.items.count);
    self.items[idx].name = [NSString stringWithFormat:@"Item %02lu 🔴%ld",
                            (unsigned long)(idx + 1), (long)++_modelChangeCount];
    // ← 只修改 model 属性，不调用 reloadData / reloadRowsAtIndexPaths:
    // 若该 Cell 可见，KVO 驱动 nameLabel 立即更新；不可见则下次 rebind 时同步
    [self p_updateStatus];
}

/// 修改所有 item 的 name（最直观地展示 KVO 批量更新，vs. 传统方式需要 reloadData）
- (void)p_onRenameAll {
    for (NSUInteger i = 0; i < self.items.count; i++) {
        self.items[i].name = [NSString stringWithFormat:@"Item %02lu 🟢%ld",
                              (unsigned long)(i + 1), (long)++_modelChangeCount];
    }
    // ← 同样不调用 reloadData。所有可见 Cell 通过 KVO 立即更新。
    [self p_updateStatus];
}

// MARK: - 动态高度演示

/// 展开一条随机 item 的详情（model 改变 → KVO → detailLabel → onHeightChanged → 重算高度）
- (void)p_onExpandDetail {
    NSUInteger idx = arc4random_uniform((uint32_t)self.items.count);
    _detailExpandCount++;
    NSString *detail = [NSString stringWithFormat:
        @"展开第 %ld 次 — detail 内容由 JHBinder 实时写入 label（rebindTo: 内容更新），"
        "高度变化由 reloadRows: 处理。两者各司其职。",
        (long)_detailExpandCount];
    self.items[idx].detail = detail;
    // 高度变化需要 reloadRows: 重新测量该行
    // 内容更新（name/tapCount）仍由 rebindTo: 无就处理，不过 reloadData
    NSIndexPath *ip = [NSIndexPath indexPathForRow:(NSInteger)idx inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self p_updateStatus];
}

/// 收起所有详情
- (void)p_onCollapseAll {
    for (V18CellDemoItemModel *item in self.items) {
        item.detail = @"";
    }
    [self.tableView reloadData];
    [self p_updateStatus];
}

@end
