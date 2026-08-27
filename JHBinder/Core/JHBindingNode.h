//
//  JHBindingNode.h
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//
//  单个绑定节点：持有 target 的弱引用、keyPath、绑定方向及转换 Block
//

#import <UIKit/UIKit.h>
#import "JHBinderDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface JHBindingNode : NSObject

// MARK: - 基本属性
@property (nonatomic, weak, nullable) id target;      ///< 弱引用，防止循环引用
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) NSString *targetHash;     ///< target 释放后仍可识别节点
@property (nonatomic, assign) JHBindDirection direction;
@property (nonatomic, copy, nullable) JHConvertBlock convertBlock;
@property (nonatomic, copy, nullable) JHNodeFilterBlock receiveFilterBlock; ///< 节点级过滤（v1.3），返回 NO 则跳过本节点，不影响其他节点
@property (nonatomic, copy, nullable) JHOutBlock outBlock; ///< 纯 block 订阅（无 target）

// MARK: - UI Control 专用
@property (nonatomic, assign) BOOL isUIControl;
@property (nonatomic, assign) UIControlEvents controlEvent;
@property (nonatomic, strong, nullable) id lastBroadcastValue; ///< distinct 用：UIControl 上次广播值

/// 节点唯一 ID（格式：targetHash_keyPath），用于 map 中的 key
@property (nonatomic, copy, readonly) NSString *nodeID;

// MARK: - 初始化
/// 普通属性节点（KVO）
- (instancetype)initWithTarget:(id)target
                       keyPath:(NSString *)keyPath
                     direction:(JHBindDirection)direction
                  convertBlock:(nullable JHConvertBlock)convertBlock;

/// UIControl 节点（Target-Action）
- (instancetype)initWithTarget:(id)target
                       keyPath:(NSString *)keyPath
                  controlEvent:(UIControlEvents)controlEvent
                     direction:(JHBindDirection)direction
                  convertBlock:(nullable JHConvertBlock)convertBlock;

/// 纯 block 订阅节点（无 target，只接收广播）
+ (instancetype)nodeWithOutBlock:(JHOutBlock)outBlock key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
