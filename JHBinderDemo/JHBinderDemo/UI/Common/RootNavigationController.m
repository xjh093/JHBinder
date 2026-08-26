//
//  RootNavigationController.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//

#import "RootNavigationController.h"

@implementation RootNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationBar.tintColor = UIColor.systemBlueColor;
    self.navigationBar.titleTextAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17]
    };

    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = UIColor.systemBackgroundColor;
        self.navigationBar.standardAppearance = appearance;
        self.navigationBar.scrollEdgeAppearance = appearance;
    }
}

@end
