//
//  LoginController.h
//  Briefcase
//
//  Created by Michael Taylor on 29/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ModalController.h"

typedef enum {
    kSavePassword = 0,
    kInstallPublicKey = 1
} AutoLoginType;

@interface LoginController : ModalController <UIAlertViewDelegate>
{
    IBOutlet UITextField        * myUsernameField;
    IBOutlet UITextField        * myPasswordField;
    IBOutlet UISwitch           * myAutoLoginSwitch;
    IBOutlet UISegmentedControl * myAutoLoginType;
    IBOutlet UILabel            * myErrorMessageLabel;
    NSString                    * myUsername;
    NSString                    * myPassword;
    NSString                    * myHostName;
    NSString                    * myDisplayName;
    NSString                    * myErrorMessage;
}
    
@property (nonatomic,copy)   NSString       * hostName;
@property (nonatomic,retain) NSString       * password;
@property (nonatomic,retain) NSString       * username;
@property (nonatomic,retain) NSString       * displayName;
@property (nonatomic,retain) NSString       * errorMessage;
@property (nonatomic,assign) BOOL             autoLogin;
@property (nonatomic,assign) AutoLoginType    autoLoginType;

- (void)usernameChanged:(id)sender;
- (void)autoLoginTypeChanged:(id)sender;

@end
