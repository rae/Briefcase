//
//  BriefcaseAppDelegate.h
//  Briefcase
//
//  Created by Michael Taylor on 01/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ConnectionController;
@class DualViewController;

@interface BriefcaseAppDelegate : NSObject {
    UIWindow *			portraitWindow;
    UITabBarController *	tabController;
    ConnectionController *	connectionController;
    
    DualViewController *	myDualViewController;
}

+ (BriefcaseAppDelegate*)sharedAppDelegate;

- (UIViewController*)createConnectViews;
- (UIViewController*)createDownloadViews;
- (UIViewController*)createUploadViews;
- (UIViewController*)createActivityViews;

- (void)pushFullScreenView:(UIViewController*)view_controller;
- (void)popFullScreenView;

- (void)gotoConnectTab;

@property (nonatomic, retain) UIWindow *portraitWindow;
@property (nonatomic, retain) UITabBarController *tabController;
@property (nonatomic, retain) ConnectionController *connectionController;

@end
