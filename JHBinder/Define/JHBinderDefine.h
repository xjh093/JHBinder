//
//  JHBinderDefine.h
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//

#ifndef JHBinderDefine_h
#define JHBinderDefine_h

#import <UIKit/UIKit.h>

// MARK: - 版本号
#define JHBinderVersionString   @"1.0.0"
#define JHBinderVersionNumber   0x010000  ///< 高8位Major，中8位Minor，低8位Patch


// MARK: - 绑定方向（位掩码）
typedef NS_OPTIONS(NSUInteger, JHBindDirection) {
    JHBindDirectionNone    = 0,
    JHBindDirectionListen  = 1 << 0,  ///< IN：监听此节点变化，向链广播
    JHBindDirectionReceive = 1 << 1,  ///< OUT：接收链广播，更新此节点
    JHBindDirectionBoth    = JHBindDirectionListen | JHBindDirectionReceive, ///< 双向
};


// MARK: - Block 类型
/// 值转换：输入旧值，返回新值（用于类型转换，如 NSString -> NSNumber）
typedef id _Nullable (^JHConvertBlock)(id _Nullable value);

/// 过滤：返回 YES 则允许广播，返回 NO 则拦截
typedef BOOL (^JHFilterBlock)(id _Nullable oldValue, id _Nullable newValue);

/// 输出回调：接收广播时触发
typedef void (^JHOutBlock)(id _Nullable value);


#endif /* JHBinderDefine_h */
