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
@property (nonatomic, assign) NSInteger  modelChangeCount; ///< model 被修改次数
@end

@implementation V18CellDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"rebindTo: Cell 复用";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.items = [V18CellDemoItemModel makeList:40];
    [self p_buildUI];
    [self p_buildNavBar];
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

    // ── "全程未调用 reloadData" 高亮提示 ─────────────────────────
    _kvoHintLabel = [[UILabel alloc] init];
    _kvoHintLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _kvoHintLabel.textColor = [UIColor systemGreenColor];
    _kvoHintLabel.textAlignment = NSTextAlignmentCenter;
    _kvoHintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_kvoHintLabel];

    // ── 说明文字 ─────────────────────────────────────────────────
    UILabel *hint = [[UILabel alloc] init];
    hint.text = @"Cell 内绑定建立一次，复用时 rebindTo: 热替换目标。\n"
                @"改名按钮修改 model，可见 Cell 通过 KVO 立即更新。";
    hint.font = [UIFont systemFontOfSize:11];
    hint.textColor = [UIColor secondaryLabelColor];
    hint.textAlignment = NSTextAlignmentCenter;
    hint.numberOfLines = 0;
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:hint];

    // ── TableView ────────────────────────────────────────────────
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.rowHeight  = 52;
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

        [hint.topAnchor constraintEqualToAnchor:_kvoHintLabel.bottomAnchor],
        [hint.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [hint.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],

        [_tableView.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:4],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self p_updateStatus];
}

- (void)p_buildNavBar {
    // 两个按钮：单条改名 / 全部改名
    UIBarButtonItem *all = [[UIBarButtonItem alloc]
        initWithTitle:@"全改"
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(p_onRenameAll)];

    UIBarButtonItem *one = [[UIBarButtonItem alloc]
        initWithTitle:@"改一条"
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(p_onRenameOne)];

    self.navigationItem.rightBarButtonItems = @[all, one];
}

- (void)p_updateStatus {
    _statusLabel.text = [NSString stringWithFormat:
        @"建立绑定 %ld 次  |  rebindTo: %ld 次  |  model 改动 %ld 次",
        (long)_bindCount, (long)_rebindCount, (long)_modelChangeCount];

    // 绿色提示：只要有 model 被改动过，就强调"全程未调用 reloadData"
    _kvoHintLabel.text = _modelChangeCount > 0
        ? [NSString stringWithFormat:@"✅ model 共改动 %ld 次，全程未调用 reloadData", (long)_modelChangeCount]
        : @"← 点击右上角按钮修改 model，观察 Cell 实时响应";
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

@end
