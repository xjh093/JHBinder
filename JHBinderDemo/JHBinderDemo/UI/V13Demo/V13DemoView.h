//
//  V13DemoView.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/26/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface V13DemoView : UIView

// MARK: - Section 1: nodeMap + nodeFilter（分流显示）
@property (nonatomic, strong, readonly) UITextField *filterField;        ///< 输入文本
@property (nonatomic, strong, readonly) UILabel     *shortLabel;         ///< 长度 < 5：显示 "💬 xxx"
@property (nonatomic, strong, readonly) UILabel     *longLabel;          ///< 长度 >= 5：显示 "📝 xxx"

// MARK: - Section 2: combineLatest（姓名合并）
@property (nonatomic, strong, readonly) UITextField *firstNameField;
@property (nonatomic, strong, readonly) UITextField *lastNameField;
@property (nonatomic, strong, readonly) UILabel     *fullNameLabel;      ///< 合并结果
@property (nonatomic, strong, readonly) UIButton    *submitButton;       ///< 两个输入框都非空时才 enabled

@end

NS_ASSUME_NONNULL_END
