//
//  ModalController.h
//  Briefcase
//
//  Created by Michael Taylor on 29/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

enum LoginState {
    kWaiting,
    kDone,
    kCancelled
};

@interface ModalController : UIViewController {
    enum LoginState		myState;
    UINavigationController *	myNavigationController;
    
    IBOutlet UINavigationBar *  myNavigationBar;
    
    id				myTarget;
    SEL				myAction;
}

@property (readonly)	     BOOL   wasCancelled;

@property (nonatomic,retain) id	    target;
@property (nonatomic,assign) SEL    action;

- (void)done;
- (IBAction)cancelled;

- (BOOL)presentModalView:(UINavigationController*)nav_controller;

@end
