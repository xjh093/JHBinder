//
//  V16DemoView.h
//  JHBinderDemo
//
//  Created by Haomissyou on 8/27/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface V16DemoView : UIScrollView

// ① merge
@property (nonatomic, strong, readonly) UITextField *usernameField;
@property (nonatomic, strong, readonly) UITextField *passwordField;
@property (nonatomic, strong, readonly) UILabel     *mergeResultLabel;

// ② withLatestFrom
@property (nonatomic, strong, readonly) UITextField *keywordField;
@property (nonatomic, strong, readonly) UITextField *categoryField;
@property (nonatomic, strong, readonly) UILabel     *wlfResultLabel;

// ③ startWith
@property (nonatomic, strong, readonly) UILabel     *startWithLabel;

// ④ tap
@property (nonatomic, strong, readonly) UITextField *tapTextField;
@property (nonatomic, strong, readonly) UILabel     *tapCountLabel;

// ⑤ negate
@property (nonatomic, strong, readonly) UIButton    *negateButton;
@property (nonatomic, strong, readonly) UILabel     *negateStateLabel;

// ⑥ mapTo
@property (nonatomic, strong, readonly) UITextField *mapToField;
@property (nonatomic, strong, readonly) UILabel     *mapToResultLabel;

// ⑦ distinctWhen
@property (nonatomic, strong, readonly) NSArray<UIButton *> *caseButtons;   ///< apple / Apple / APPLE / banana / Banana
@property (nonatomic, strong, readonly) UILabel     *caseResultLabel;
@property (nonatomic, strong, readonly) UILabel     *caseBroadcastLabel;  ///< 展示实际触发次数

// ⑧ takeWhile / skipWhile
@property (nonatomic, strong, readonly) UIButton    *counterIncrButton;
@property (nonatomic, strong, readonly) UILabel     *takeWhileLabel;
@property (nonatomic, strong, readonly) UILabel     *skipWhileLabel;

@end

NS_ASSUME_NONNULL_END
