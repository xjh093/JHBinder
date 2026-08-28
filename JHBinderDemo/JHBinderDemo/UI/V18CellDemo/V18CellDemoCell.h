//
//  V18CellDemoCell.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/28/26.
//
//  演示 rebindTo:keyPath: 在 Cell 复用场景下的正确用法：
//  绑定链只在 Cell 首次使用时建立一次；
//  复用时调用 rebindTo:keyPath: 热替换监听目标，无需销毁重建。
//

#import <UIKit/UIKit.h>
@class V18CellDemoItemModel;

NS_ASSUME_NONNULL_BEGIN

@interface V18CellDemoCell : UITableViewCell

/// 将 Cell 绑定到指定 Model。
/// - 首次调用：建立 KVO 绑定，立即显示当前值。
/// - 复用调用：热替换监听目标（rebindTo:keyPath:），立即刷新为新 Model 的值。
- (void)bindToModel:(V18CellDemoItemModel *)model;

@end

NS_ASSUME_NONNULL_END
