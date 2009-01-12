//
//  DualNavigationViewController.h
//  navtest
//
//  Created by Michael Taylor on 14/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DualViewController : UIViewController 
{
    UIViewController *	myMainController;
    UIViewController *	myAlternateViewController;
}

@property (readonly,nonatomic) UIViewController * mainController;

- (id)initWithViewController:(UIViewController *)mainViewController;

- (void)pushAlternateViewController:(UIViewController *)viewController;
- (void)popAlternateViewController;

@end
