//
//  MainViewController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  示例列表页，点击跳转对应 Demo
//

#import "MainViewController.h"
#import "BasicDemoViewController.h"
#import "TextFieldDemoViewController.h"
#import "SliderDemoViewController.h"
#import "LoginDemoViewController.h"
#import "ConvertDemoViewController.h"

static NSString * const kCellID = @"MainCell";

@interface MainViewController ()

@property (nonatomic, strong) NSArray<NSDictionary *> *items;
//  每项格式: @{ @"title": @"xxx", @"class": @"XxxViewController" }

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"JHBinder Demo";
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kCellID];
    self.tableView.rowHeight = 52;

    self.items = @[
        @{ @"title": @"01  基础绑定（Model ↔ TextField ↔ Label）",
           @"class": @"BasicDemoViewController" },
        @{ @"title": @"02  UITextField + 过滤 + 值转换",
           @"class": @"TextFieldDemoViewController" },
        @{ @"title": @"03  UISlider ↔ Label + ProgressView",
           @"class": @"SliderDemoViewController" },
        @{ @"title": @"04  MVVM 登录界面",
           @"class": @"LoginDemoViewController" },
        @{ @"title": @"05  twoWayMap（接收转换 vs 广播原始值）",
           @"class": @"ConvertDemoViewController" },
        @{ @"title": @"06  v1.2 新特性（fire / debounce / delay / distinct / once）",
           @"class": @"V12DemoViewController" },
        @{ @"title": @"07  v1.3 新特性（nodeMap / nodeFilter / combineLatest）",
           @"class": @"V13DemoViewController" },
        @{ @"title": @"08  v1.4 新特性（defaultValue / skip / take / throttle）",
           @"class": @"V14DemoViewController" },
        @{ @"title": @"09  v1.5 新特性（transform / scan / withPrevious）",
           @"class": @"V15DemoViewController" },
        @{ @"title": @"10  v1.6 新特性（merge / withLatestFrom / startWith / tap / negate / mapTo / distinctWhen / takeWhile / skipWhile）",
           @"class": @"V16DemoViewController" },
        @{ @"title": @"11  v1.7 新特性（interval / takeUntil / pluck / bufferCount / bufferTime / timeout / sample / combine / elementAt）",
           @"class": @"V17DemoViewController" },
        @{ @"title": @"12  v1.8 新特性（format / notNil / required / pausable / rebindTo:keyPath:）",
           @"class": @"V18DemoViewController" },
        @{ @"title": @"13  v1.8 rebindTo: — Cell 复用列表实战",
           @"class": @"V18CellDemoViewController" },
    ];
}

// MARK: - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID forIndexPath:indexPath];
    cell.textLabel.text = self.items[indexPath.row][@"title"];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *className = self.items[indexPath.row][@"class"];
    Class cls = NSClassFromString(className);
    if (!cls) return;

    UIViewController *vc = [[cls alloc] init];
    vc.title = [self.items[indexPath.row][@"title"] substringFromIndex:4]; // 去掉序号前缀
    [self.navigationController pushViewController:vc animated:YES];
}

@end
