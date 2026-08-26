//
//  AppDelegate.m
//  JHBinderDemo
//
//  Created by Haomissyou on 8/25/26.
//

#import "AppDelegate.h"
#import "RootNavigationController.h"
#import "MainViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;

    MainViewController *mainVC = [[MainViewController alloc] init];
    RootNavigationController *nav = [[RootNavigationController alloc] initWithRootViewController:mainVC];
    self.window.rootViewController = nav;

    [self.window makeKeyAndVisible];
    return YES;
}

@end
