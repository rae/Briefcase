//
//  ConnectionController.h
//  Briefcase
//
//  Created by Michael Taylor on 05/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCConnection.h"
#import "LoginController.h"

@class BonjourBrowserController;
@class InternetBrowserController;
@class ConnectedController;
@class SystemInformation;
@class ConnectionBrowserController;

extern NSString * kMainConnectionEstablished;
extern NSString * kMainConnectionTerminated;

@interface ConnectionController : UIViewController <BCConnectionDelegate, 
						    UIActionSheetDelegate, 
						    UIAlertViewDelegate,
						    UINavigationControllerDelegate> 
{
    UINavigationController *	    myNavigationController;

    IBOutlet UITableView *	    myTableView;
    
    IBOutlet ConnectedController *  myConnectedController;
    
    BCConnection *		    myConnection;
    NSString *			    myConnectionName;
    
    NSInteger			    myButtonIndex;
	
    id				    myRequestObject;
    KeychainItem *		    myRequestKeychain;
    SEL				    myRequestAction;
    SEL				    myRequestCancelledAction;
    
    BOOL			    myIsInterBriefcaseConnection;
    
    IBOutlet ConnectionBrowserController * myConnectionBrowserController;
}

@property (nonatomic,readonly) BCConnection *		currentConnection;
@property (nonatomic,readonly) SystemInformation *	currentSystemInformation;
@property (nonatomic,readonly) BOOL			isInterBriefcaseConnection;
@property (nonatomic,retain)   UINavigationController *	navigationController;

+ (ConnectionController*)sharedController;

- (void)connectTo:(NSNetService*)service;
- (void)connectToHost:(NSString*)host 
	       atPort:(NSUInteger)port 
	 withUsername:(NSString*)username
	  displayName:(NSString*)display_name;

- (void)disconnect;

// SSHConnection delegate methods

- (BOOL)allowConnectionToHost:(NSString*)host withHash:(NSData*)hash;

- (void)requestUsernameAndPassword:(KeychainItem*)item 
			    target:(id)object 
		   successSelector:(SEL)success_selector
		 cancelledSelector:(SEL)cancelled_selector
		      errorMessage:(NSString*)error_message;

- (BOOL)warnAboutChangedHash;

// UIAlertView delegate method

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

// NSNetService delegate methods

- (void)netServiceDidResolveAddress:(NSNetService *)sender;
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict;

- (void)_serviceDidResolve:(NSNetService *)sender;

@end
