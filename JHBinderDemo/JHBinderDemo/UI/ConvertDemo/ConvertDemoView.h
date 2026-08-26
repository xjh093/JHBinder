//
//  ConvertDemoView.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  布局：
//    rawField        ← twoWayUI，直接双向同步
//    upperField      ← twoWayUIMap，接收时转大写；广播时传原始值
//    trimField       ← twoWayUIMap，接收时去首尾空格；广播时传原始值
//    modelLabel      ← receive，显示 model.text 当前值
//    setValueBtn     ← 代码写入固定值（含首尾空格），验证 trimField 转换
//

#import <UIKit/UIKit.h>

@interface ConvertDemoView : UIView

@property (nonatomic, strong, readonly) UITextField *rawField;
@property (nonatomic, strong, readonly) UITextField *upperField;
@property (nonatomic, strong, readonly) UITextField *trimField;
@property (nonatomic, strong, readonly) UILabel     *modelLabel;
@property (nonatomic, strong, readonly) UIButton    *setValueBtn;

@end
