//
//  TextFieldDemoView.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  布局：textField1 / textField2（双向同步）/ Label 原始值 / Label 大写转换 / 字数限制提示
//

#import <UIKit/UIKit.h>

@interface TextFieldDemoView : UIView

@property (nonatomic, strong, readonly) UITextField *textField1;   ///< 输入源 A
@property (nonatomic, strong, readonly) UITextField *textField2;   ///< 输入源 B（与 A 双向同步）
@property (nonatomic, strong, readonly) UILabel     *labelNormal;  ///< receive：原始文本
@property (nonatomic, strong, readonly) UILabel     *labelUpper;   ///< receiveMap：转大写
@property (nonatomic, strong, readonly) UILabel     *counterLabel; ///< 字数统计

@end
