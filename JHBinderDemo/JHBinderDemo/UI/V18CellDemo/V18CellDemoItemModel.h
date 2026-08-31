//
//  V18CellDemoItemModel.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/28/26.
//
//  rebindTo:keyPath: 列表复用演示 — 数据模型
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface V18CellDemoItemModel : NSObject

@property (nonatomic, copy)   NSString *name;       ///< 条目名称（可被修改以测试 KVO 更新）
@property (nonatomic, strong) NSNumber *tapCount;   ///< 按钮点击次数（从 @0 累加）
@property (nonatomic, copy)   NSString *detail;     ///< 详情文本（空=单行，长文本=多行，演示动态高度）

+ (NSMutableArray<V18CellDemoItemModel *> *)makeList:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
