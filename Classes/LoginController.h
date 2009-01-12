//
//  LoginController.h
//  Briefcase
//
//  Created by Michael Taylor on 29/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ModalController.h"

@interface LoginController : ModalController <UIAlertViewDelegate>
{
    IBOutlet UITextField     * myUsernameField;
    IBOutlet UITextField     * myPasswordField;
    IBOutlet UISwitch	     * myRememberSwitch;
    IBOutlet UILabel	     * myErrorMessageLabel;
    NSString		     * myUsername;
    NSString		     * myPassword;
    NSString		     * myHostName;
    NSString		     * myDisplayName;
    NSString		     * myErrorMessage;
}

@property (nonatomic,copy)   NSString * hostName;
@property (nonatomic,retain) NSString * password;
@property (nonatomic,retain) NSString * username;
@property (nonatomic,retain) NSString * displayName;
@property (nonatomic,retain) NSString * errorMessage;
@property (nonatomic,assign) BOOL	rememberPassword;

- (void)usernameChanged:(id)sender;

@end
