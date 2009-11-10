//
//  ConnectedController.m
//  Briefcase
//
//  Created by Michael Taylor on 08/06/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ConnectedController.h"
#import "ConnectionController.h"
#import "ConnectedView.h"
#import "SystemInformation.h"
#import "SystemInfoController.h"
#import "IconManager.h"
#import "KeychainItem.h"

@implementation ConnectedController

@dynamic hostName;
@synthesize isBriefcaseConnection = myIsBriefcaseConnection;

- (id)init 
{
    if (self = [super initWithNibName:@"ConnectionView" bundle:nil])
    {
    }
    
    return self;
}

- (void) awakeFromNib
{
    self.navigationItem.hidesBackButton = YES;	
    
    myConnectingTitle = [NSLocalizedString(@"Connecting", @"Title for screen while we are connecting") retain];
    myConnectedTitle = [NSLocalizedString(@"Connected", @"Title for screen once we have connected") retain];
    self.navigationItem.title = myConnectingTitle;
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self 
	       selector:@selector(systemInformationChanged:) 
		   name:kSystemInfoChanged
		 object:nil];
    
    [center addObserver:self 
	       selector:@selector(connectionEstablished:) 
		   name:kMainConnectionEstablished 
		 object:nil];
    
    [center addObserver:self 
	       selector:@selector(connectionTerminated:) 
		   name:kMainConnectionTerminated
		 object:nil];    
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

- (void)viewDidLoad 
{
    ConnectedView * view = (ConnectedView*)self.view;
    view.hostIcon = [IconManager iconForGenericServer];
    
    UIImage * image = [UIImage imageNamed:@"button.png"];
    image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    [myDisconnectButton setBackgroundImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"button_pressed.png"];
    image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    [myDisconnectButton setBackgroundImage:image forState:UIControlStateHighlighted];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [mySystemInfoController release];
    [super dealloc];
}

- (IBAction)disconnect:(id)sender
{
    ConnectionController * controller = [ConnectionController sharedController];
    [controller disconnect];
}

- (void)beginConnection
{
}

- (void)connectionEstablished:(NSNotification*)notification
{
    ConnectedView * view = (ConnectedView*)self.view;
    [view setConnected:YES];
    self.navigationItem.title = myConnectedTitle;
}

- (void)connectionTerminated:(NSNotification*)notification
{
    ConnectedView * view = (ConnectedView*)self.view;
    [view setConnected:NO];
    self.navigationItem.title = myConnectingTitle;
    
    // Reset icon
    self.isBriefcaseConnection = myIsBriefcaseConnection;
}

- (void)systemInformationChanged:(NSNotification*)notification
{
    // Check if we need to update the icon
    ConnectionController * controller = [ConnectionController sharedController];
    SystemInformation * info = controller.currentSystemInformation;
    
    if (info && info.isConnectedToMac)
    {
	ConnectedView * view = (ConnectedView*)self.view;
	view.hostIcon = [IconManager iconForMacModel:info.macModel 
					   smallIcon:YES];
    }
}

- (IBAction)showSystemInformation:(id)sender
{
    if (!mySystemInfoController)
	mySystemInfoController = [[SystemInfoController alloc] init];
    
    UINavigationController * nav_controller = (UINavigationController*)[self parentViewController];
    [nav_controller pushViewController:mySystemInfoController animated:YES];
}

- (IBAction)clearKeychain:(id)sender
{
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:@""
				       message:NSLocalizedString(@"Do you wish to clear all stored passwords from your keychain?", @"Message asking the user if they want to erase all of their passwords")
				      delegate:self 
			     cancelButtonTitle:NSLocalizedString(@"No", @"No")
			     otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0)
    {
	[KeychainItem cleanKeychain];
    }
}

#pragma mark Properties

- (NSString*)hostName
{
    return self.navigationItem.title;
}

- (void)setHostName:(NSString*)name
{
    ConnectedView * view = (ConnectedView*)self.view;
    view.hostName = name;
}

- (void)setIsBriefcaseConnection:(BOOL)connection
{
    ConnectedView * view = (ConnectedView*)self.view;
    if (connection)
	view.hostIcon = [IconManager iconForiPhone];
    else
	view.hostIcon = [IconManager iconForGenericServer];
}


@end
