//
//  AddRemoteHostController.h
//  Briefcase
//
//  Created by Michael Taylor on 29/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditRemoteHostController : UIViewController <UITextFieldDelegate>
{
    UINavigationController * myNavigationController;
    
    IBOutlet UITextField * myNicknameField;
    IBOutlet UITextField * myServerAddressField;
    IBOutlet UITextField * myPortNumberField;
    IBOutlet UITextField * myUsernameField;
    
    NSString *		   myNickname;
    NSString *		   myServerAddress;
    NSUInteger		   myPort;
    NSString *		   myUsername;
    
    id			   myTarget;
    SEL			   myAction;
    
    BOOL		   myCancelled;
}

@property (nonatomic,retain) NSString * nickname;
@property (nonatomic,retain) NSString * serverAddress;
@property (nonatomic,assign) NSUInteger port;
@property (nonatomic,retain) NSString * username;

@property (nonatomic,retain) id		target;
@property (nonatomic,assign) SEL	action;

@property (nonatomic,readonly) BOOL	cancelled;

- (id)initWithNavigationController:(UINavigationController*)controller;

- (IBAction)fieldValueChanged:(id)sender;

@end
