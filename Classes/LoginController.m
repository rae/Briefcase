//
//  LoginController.m
//  Briefcase
//
//  Created by Michael Taylor on 29/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "LoginController.h"
#import "TextFieldCell.h"
#import "UICell.h"
#import "KeychainKeyPair.h"
#import "ConnectionController.h"

static NSString * kWarnedToLockDevice = @"kWarnedToLockDevice";
static NSString * kAutoLoginTypeKey = @"kAutoLoginTypeKey";
@implementation LoginController

- (id)init 
{
    if (self = [super initWithNibName:@"LoginView" bundle:nil]) {
	// Initialization code
	myUsername = nil;
	myPassword = nil;
    }
    
    NSString * extra = NSLocalizedString(@"Use short username (see FAQ)",@"Warn the user to use their short username for logging in (do not translate 'FAQ')");
        
    return self;
}

- (void)dealloc {
    [myUsername release];
    [myPassword release];
    [super dealloc];
}

- (void)viewDidLoad
{
    self.navigationItem.title = myDisplayName;
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    self.autoLoginType = [defaults integerForKey:kAutoLoginTypeKey];
    self.autoLogin = NO;
    
    myUsernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    myUsernameField.clearsOnBeginEditing = NO;
    myUsernameField.font = [UIFont systemFontOfSize:20.0];
    
    myPasswordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    myPasswordField.clearsOnBeginEditing = YES;
    myPasswordField.font = [UIFont systemFontOfSize:20.0];
    
    [super viewDidLoad];
}

- (void)warnUserAboutPasswords
{
    UIAlertView * warn_alert;
    warn_alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Keychain Warning", @"Title for message to user warning them to lock their devices") 
					    message:NSLocalizedString(@"Warning: If you save passwords to the keychain it is strongly recommended that you turn on the Passcode Lock feature of the iPhone.", @"Warning displayed to user the first time they save a password")
					   delegate:self 
				  cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label") 
				  otherButtonTitles:NSLocalizedString(@"OK", @"Label for OK button"), nil];
    [warn_alert show];
    [warn_alert release];   
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
	myAutoLoginSwitch.on = NO;
    else
	[self done];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    BOOL has_been_warned = [defaults boolForKey:kWarnedToLockDevice];
    
    if (!has_been_warned && self.autoLogin)
    {
	[self warnUserAboutPasswords];
	[defaults setBool:YES forKey:kWarnedToLockDevice];
    }
    else
	[self done];
    
    return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    myUsernameField.text = myUsername;
    myPasswordField.text = myPassword;
    
    if ([myUsername length] == 0)
	[myUsernameField becomeFirstResponder];
    else
	[myPasswordField becomeFirstResponder];
    
    if (myErrorMessage)
	myErrorMessageLabel.text = myErrorMessage;
}

- (void)done
{
    myUsername = [myUsernameField.text copy];
    myPassword = [myPasswordField.text copy];
    
    [super done];
}

- (void)usernameChanged:(id)sender
{
    NSRange whitespace_range = [[sender text] rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (whitespace_range.location != NSNotFound)
	// Warn the user to user their short username
	myErrorMessageLabel.text = NSLocalizedString(@"Use short username (see FAQ)", @"Warn the user to use their short username for logging in (do not translate 'FAQ')");
    else
	myErrorMessageLabel.text = @"";
}

- (void)autoLoginTypeChanged:(id)sender
{
    if (self.autoLoginType == kInstallPublicKey)
    {
        ConnectionController * controller = [ConnectionController sharedController];
        [controller ensureSSHKeyPairCreated];
    }
}

#pragma mark Properties

@synthesize hostName = myHostName; 
@synthesize displayName = myDisplayName;
@synthesize errorMessage = myErrorMessage;
@dynamic password;
@dynamic username;

- (NSString*)username
{
    return myUsername;
}

- (void)setUsername:(NSString*)username
{
    [myUsername release];
    myUsername = [username retain];
    myUsernameField.text = username;
}

- (NSString*)password
{
    return myPassword;
}

- (void)setPassword:(NSString*)password
{
    [myPassword release];
    myPassword = [password retain];
    myPasswordField.text = password;
}

- (BOOL)autoLogin
{
    return myAutoLoginSwitch.on;
}

- (void)setAutoLogin:(BOOL)auto_login
{
    myAutoLoginSwitch.on = auto_login;
}

- (AutoLoginType)autoLoginType
{
    return myAutoLoginType.selectedSegmentIndex;
}

- (void)setAutoLoginType:(AutoLoginType)auto_login_type
{
    myAutoLoginType.selectedSegmentIndex = auto_login_type;
}

@end
