//
//  BasicDemoView.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//
//  布局：说明标签 / UITextField / UILabel（同步显示）/ UIButton（写入固定值）
//

#import <UIKit/UIKit.h>

@interface BasicDemoView : UIView

@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, strong, readonly) UILabel     *syncLabel;
@property (nonatomic, strong, readonly) UIButton    *setValueBtn;

@end
