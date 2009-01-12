//
//  AddRemoteHostController.m
//  Briefcase
//
//  Created by Michael Taylor on 29/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "EditRemoteHostController.h"


@implementation EditRemoteHostController

@synthesize nickname = myNickname;
@synthesize serverAddress = myServerAddress;
@synthesize port = myPort;
@synthesize username = myUsername;

@synthesize target = myTarget;
@synthesize action = myAction;

@synthesize cancelled = myCancelled;

- (id)initWithNavigationController:(UINavigationController*)controller 
{
    if (self = [super initWithNibName:@"AddRemoteHostView" bundle:nil]) 
    {
	myNavigationController = [controller retain];
    }
    return self;
}

- (void)dealloc 
{
    [myNavigationController release];
    [myNickname release];
    [myServerAddress release];
    [myUsername release];
    [super dealloc];
}

- (void)viewDidLoad
{        
    [super viewDidLoad];
    
    myNicknameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    myServerAddressField.clearButtonMode = UITextFieldViewModeWhileEditing;
    myUsernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    myNicknameField.text = @"";
    myServerAddressField.text = @"";
    myUsernameField.text = @"";
    
    myNicknameField.font = [UIFont systemFontOfSize:18.0];
    myServerAddressField.font = [UIFont systemFontOfSize:18.0];
    myPortNumberField.font = [UIFont systemFontOfSize:18.0];
    myUsernameField.font = [UIFont systemFontOfSize:18.0];
    
    self.navigationItem.title = NSLocalizedString(@"Add Remote Host", @"Title for screen where you add a new remote host to bookmark list");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave 
											   target:self 
											   action:@selector(done)];
}

- (BOOL)validateFields
{
    if ([myNicknameField.text length] > 0 &&
	[myServerAddressField.text length] > 0 &&
	[myPortNumberField.text length] > 0 )
    {
	self.navigationItem.rightBarButtonItem.enabled = YES;
	return YES;
    }
    else
    {
	self.navigationItem.rightBarButtonItem.enabled = NO;
	return NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{   
    [super viewDidAppear:animated];
    
    myCancelled = YES;
    
    myNicknameField.text = myNickname;
    myServerAddressField.text = myServerAddress;
    NSNumber * number = [NSNumber numberWithUnsignedInt:myPort];
    myPortNumberField.text = [number stringValue];
    myUsernameField.text = myUsername;
    
    [self fieldValueChanged:self];
    
    [myNicknameField becomeFirstResponder];    
    
    [self validateFields];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)fieldValueChanged:(id)sender
{
    // The address field must have text for this edit to complete
    self.navigationItem.rightBarButtonItem.enabled = [myServerAddressField.text length] > 0;
}

- (void)done
{
    myNickname = [myNicknameField.text copy];
    myServerAddress = [myServerAddressField.text copy];
    
    NSScanner * scanner = [NSScanner scannerWithString:myPortNumberField.text];
    int value;
    if(![scanner scanInt:&value])
	value = 0;
    myPort = (NSUInteger)value;
    
    myUsername = [myUsernameField.text copy];
    
    myCancelled = NO;
    
    [myNavigationController popViewControllerAnimated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (myTarget && myAction)
	[myTarget performSelector:myAction withObject:self];
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self validateFields])
    {
	[self done];
	return YES;
    }
    else
	return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
replacementString:(NSString *)string
{
    [self performSelector:@selector(validateFields) withObject:nil afterDelay:0.1];
    return YES;
}


@end
