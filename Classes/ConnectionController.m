//
//  ConnectionController.m
//  Briefcase
//
//  Created by Michael Taylor on 05/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ConnectionController.h"
#import "BCConnectionManager.h"
#import "ConnectedController.h"
#import "SystemInformation.h"
#import "KeychainItem.h"
#import "BriefcaseConnection.h"
#import "FAQController.h"
#import "ConnectionBrowserController.h"
#import "UIAlertView+Activity.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

#if BRIEFCASE_LITE
#   import "UpgradeAlert.h"
#endif

NSString * kMainConnectionEstablished = @"Main Connection Established";
NSString * kMainConnectionTerminated = @"Main Connection Terminated";

#define kRunloopCheckInterval 0.1

static ConnectionController * theConnectionController;

@implementation ConnectionController

@synthesize currentConnection = myConnection;
@synthesize isInterBriefcaseConnection = myIsInterBriefcaseConnection;
@synthesize navigationController = myNavigationController;
@dynamic currentSystemInformation;

+ (ConnectionController*)sharedController
{
    if (!theConnectionController)
	theConnectionController = [[ConnectionController alloc] init];
    return theConnectionController;
}

- (id)init
{
    if (self = [super initWithNibName:@"ConnectionBrowserView" bundle:nil]) 
    {			
	myConnection = nil;
	
	UIBarButtonItem * button = [[UIBarButtonItem alloc] initWithTitle:@"FAQ" 
								    style:UIBarButtonItemStylePlain
								   target:self
								   action:@selector(showFAQ)];
	self.navigationItem.leftBarButtonItem = button;
	
#if ! BRIEFCASE_LITE
	self.navigationItem.rightBarButtonItem = self.editButtonItem;	
#endif
	self.navigationItem.title = NSLocalizedString(@"Connect", @"Connect title");
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(networkAvailablityChanged:)
		       name:kNetworkReachibilityChanged 
		     object:nil];	
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    BCConnectionManager * manager = [BCConnectionManager sharedManager];
    myTableView.hidden = !manager.networkAvailable;
}

- (void)viewDidAppear:(BOOL)animated
{
    NSIndexPath * path = [myTableView indexPathForSelectedRow];
    if (path)
	[myTableView deselectRowAtIndexPath:path animated:YES];    
}

- (void)networkAvailablityChanged:(NSNotification*)notification
{
    BCConnectionManager * manager = [BCConnectionManager sharedManager];
    myTableView.hidden = !manager.networkAvailable;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview.
    // Release anything that's not essential, such as cached data.
}

- (void)dealloc 
{
    // Remove ourselves as table view delegate and data source 
    [myNavigationController release];
    [myConnectionBrowserController release];
    [super dealloc];
}

- (void)connectTo:(NSNetService*)service
{   
    if ([[service type] isEqualToString:@"_ssh._tcp."])
	myIsInterBriefcaseConnection = NO;
    else
	myIsInterBriefcaseConnection = YES;
	
    if ([service.addresses count] > 0)
    {
	// Already resolved
	[self _serviceDidResolve:service];
    }
    else
    {
	[service setDelegate:self];
	[service performSelectorInBackground:@selector(resolve) withObject:nil];
    }
}

- (void)connectToNetService:(NSNetService*)service
{
    if (myConnection)
    {
	[myConnection release];
	myConnection = nil;
    }
    
    [myConnectionName release];
    if ([[service name] length] > 0)
	myConnectionName = [[service name] retain];
    else
	myConnectionName = [[service hostName] retain];
    
    myConnectedController.hostName = [service hostName];
    
    if ([@"_briefcase._tcp." isEqualToString:[service type]])
	myConnectedController.isBriefcaseConnection = YES;
    else
	myConnectedController.isBriefcaseConnection = NO;
    
    [myNavigationController pushViewController:myConnectedController animated:YES];
    
    BCConnectionManager * connection_manager = [BCConnectionManager sharedManager];
    myConnection = (SSHConnection*)[[connection_manager connectForNetService:service] retain]; 

    myConnection.delegate = self;
    
    if ([[service type] isEqualToString:kSSHProtocol])
    {
	SystemInformation * info = [[SystemInformation alloc] initWithConnection:(SSHConnection*)myConnection];
	myConnection.userData = info;
	[info release];
    }
    [myConnection connect];
    
}

- (void)connectToHost:(NSString*)host 
	       atPort:(NSUInteger)port 
	 withUsername:(NSString*)username
	  displayName:(NSString*)display_name
{
    if (myConnection)
    {
	[myConnection release];
	myConnection = nil;
    }
    
    // Remote connections are never inter-briefcase
    myIsInterBriefcaseConnection = NO;
    
    [myConnectionName release];
    if (display_name && [display_name length] > 0)
	myConnectionName = [display_name retain];
    else
	myConnectionName = [host retain];
    
    myConnectedController.hostName = myConnectionName;
    myConnectedController.isBriefcaseConnection = NO;
    
    [myNavigationController pushViewController:myConnectedController animated:YES];
    
    BCConnectionManager * connection_manager = [BCConnectionManager sharedManager];
    myConnection = (SSHConnection*)[[connection_manager connectForProtocol:kSSHProtocol 
								  withHost:host 
								      port:port] retain];
    if (username)
	myConnection.username = username;
    myConnection.delegate = self;
    
    if ([myConnection protocol] == kSSHProtocol)
    {
	SystemInformation * info = [[SystemInformation alloc] initWithConnection:(SSHConnection*)myConnection];
	myConnection.userData = info;
	[info release];
    }
    [myConnection connect];
}

#if BRIEFCASE_LITE

- (void)connectToBriefcase:(NSString*)host
		    atPort:(NSUInteger)port
	       displayName:(NSString*)display_name
{
    UpgradeAlert * alert;
    alert = [[UpgradeAlert alloc] initWithMessage:NSLocalizedString(@"Briefcase Lite can only receive (not initiate) iPhones-to-iPhone connections", @"Message shown to user when they try to connect to an iPhone using Briefcase Lite")];
    [alert show];	
    [alert release];
}

#else

- (void)connectToBriefcase:(NSString*)host
		    atPort:(NSUInteger)port
	       displayName:(NSString*)display_name
{   
    // Connect to another copy of Briefcase on another iPhone/iPod Touch
    if (myConnection)
    {
	[myConnection release];
	myConnection = nil;
    }
    
    [myConnectionName release];
    if (display_name && [display_name length] > 0)
	myConnectionName = [display_name retain];
    else
	myConnectionName = [host retain];
    myConnectedController.hostName = myConnectionName;
    myConnectedController.isBriefcaseConnection = YES;
    
    [myNavigationController pushViewController:myConnectedController animated:YES];
    
    BCConnectionManager * connection_manager = [BCConnectionManager sharedManager];
    BriefcaseConnection * briefcase_connection;
    briefcase_connection = (BriefcaseConnection*)[[connection_manager connectForProtocol:kBriefcaseProtocol 
										withHost:host 
										    port:port] retain];
    myConnection = briefcase_connection;
    
    briefcase_connection.delegate = self;
    
    [briefcase_connection connect];
}

#endif

- (void)disconnect
{
    if (myConnection)
	[self connectionTerminated:myConnection];
}

- (void)showFAQ
{
    FAQController * controller = [[FAQController alloc] init];
    [myNavigationController pushViewController:controller animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [myConnectionBrowserController setEditing:editing animated:animated];
}

#pragma mark UINavigationControllerDelegate methods

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController == self)
	[self disconnect];
}

#pragma mark ConnectionDelegate methods

- (BOOL)allowConnectionToHost:(NSString*)host withHash:(NSData*)hash;
{
    BOOL result = NO;
    /*    
     HostKeychain * keychain = [HostKeychain sharedKeychain];
     
     switch ( [keychain checkHost:host withHash:hash] ) {
     case kHostOk:
     result = YES;
     break;
     case kHostUnknown:
     // We presume that if the user is trying to 
     // connect to the host, then they won't cancel
     // now.  Add the hash to our list without 
     // hassling the user
     [keychain addHost:host withHash:hash];
     result = YES;
     break;
     case kHostWrongHash:
     result = NO;
     break;
     default:
     break;
     };
     */
    result = YES;
    return result;
}

- (void)connectionEstablished:(BCConnection*)connection
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kMainConnectionEstablished object:myConnection];
}

- (void)connectionTerminated:(BCConnection*)connection
{
    if (!myConnection)
	return;
    
    [connection retain];
    
    myConnection.delegate = nil;
    [myConnection release];
    myConnection = nil;
    [myConnectionName release];
    myConnectionName = nil;    
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kMainConnectionTerminated object:myConnection];
    
    [connection release];
    
    [myNavigationController popToRootViewControllerAnimated:YES];
}

- (void)connectionFailed:(BCConnection*)connection
{
    [myNavigationController popToRootViewControllerAnimated:YES];
}

- (void)requestUsernameAndPassword:(KeychainItem*)item 
			    target:(id)object 
		   successSelector:(SEL)success_selector
		 cancelledSelector:(SEL)cancelled_selector
		      errorMessage:(NSString*)error_message
{
    myRequestObject = [object retain];
    myRequestKeychain = [item retain];
    myRequestAction = success_selector;
    myRequestCancelledAction = cancelled_selector;
        
    LoginController * login_controller = [[LoginController alloc] init];
    
    login_controller.displayName = myConnectionName;
    login_controller.username = item.username;
    login_controller.password = item.password;
    login_controller.target = self;
    login_controller.action = @selector(requestForPasswordComplete:);
    
    if (error_message)
	login_controller.errorMessage = error_message;
    
    [login_controller presentModalView:myNavigationController];
    
    [login_controller release];
}

- (void)requestForPasswordComplete:(LoginController*)controller
{
    if (controller.wasCancelled)
        [myRequestObject performSelector:myRequestCancelledAction];
    else
    {
        myRequestKeychain.username = controller.username;
        myRequestKeychain.password = controller.password;

        if (!controller.autoLogin || controller.autoLoginType == kInstallPublicKey)
        {  
            // Save the username, but clear the password temporarily
            myRequestKeychain.password = @"";
            [myRequestKeychain save];
            myRequestKeychain.password = controller.password;
        }
        else
            [myRequestKeychain save];
        
        BOOL auto_install_ssh_key;
        auto_install_ssh_key = (controller.autoLogin && 
                                controller.autoLoginType == kInstallPublicKey);
        [SSHConnection setAutoInstallPublicKey:auto_install_ssh_key];
        
        [myRequestObject performSelector:myRequestAction withObject:myRequestKeychain];
    }
    
    [myRequestObject release];
    [myRequestKeychain release];
    //    [controller release];
}

- (BOOL)warnAboutChangedHash
{
    UIAlertView * hash_alert;
    hash_alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Host's Hash Value has Changed",@"Title for warning when remote host's hash value has changed") 
					    message:NSLocalizedString(@"The crytographic key of the machine you are logging into has changed.  This could mean another computer has intercepted your login",@"Warning when remote host's hash value has changed")
					   delegate:self 
				  cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label") 
				  otherButtonTitles:NSLocalizedString(@"Continue", @"Continue button label"), nil];
    
    [hash_alert show];
    
    // Now, drive an event loop until we've got our answer
    NSRunLoop * current_loop = [NSRunLoop currentRunLoop];    
    myButtonIndex = -1;
    while (myButtonIndex < 0) 
    {
	NSDate * until = [NSDate dateWithTimeIntervalSinceNow:kRunloopCheckInterval];
	[current_loop runMode:NSDefaultRunLoopMode beforeDate:until];
    }
    
    [hash_alert release];
    
    return myButtonIndex != 0;
}

- (void)displayLoginFailed
{
    UIAlertView * hash_alert;
    hash_alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login Failed",@"Title when login failed") 
					    message:NSLocalizedString(@"Your username and password were not accepted.  Please try again.",@"Message when login failed")
					   delegate:self 
				  cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
				  otherButtonTitles:nil];
    
    [hash_alert show];
    
    // Now, drive an event loop until we've got our answer
    NSRunLoop * current_loop = [NSRunLoop currentRunLoop];    
    myButtonIndex = -1;
    while (myButtonIndex < 0) 
    {
	NSDate * until = [NSDate dateWithTimeIntervalSinceNow:kRunloopCheckInterval];
	[current_loop runMode:NSDefaultRunLoopMode beforeDate:until];
    }
    
    [hash_alert release];    
}


#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    myButtonIndex = buttonIndex;
}

#pragma mark NSNetService delegate methods

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    [self performSelectorOnMainThread:@selector(_serviceDidResolve:) 
			   withObject:sender 
			waitUntilDone:NO];
}

- (void)_serviceDidResolve:(NSNetService *)sender
{    
    NSString * host = [sender hostName];
    NSInteger port = [sender port];

    if ([@"_briefcase._tcp." isEqualToString:[sender type]])
	[self connectToBriefcase:host atPort:port displayName:[sender name]];
    else
	[self connectToNetService:sender];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    [self performSelectorOnMainThread:@selector(_serviceDidNotResolve:) 
			   withObject:errorDict 
			waitUntilDone:NO];
}

- (void)_serviceDidNotResolve:(NSDictionary *)errorDict
{
    // TODO: Error handling
    NSLog(@"Error: %@",errorDict);
}

// UIActionSheetDelegate delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    myButtonIndex = buttonIndex;
}

#pragma mark Properties

- (SystemInformation*)currentSystemInformation
{
    if (myConnection)
    {
	return (SystemInformation*)myConnection.userData;
    }
    return nil;
}

@end
