//
//  Connection.h
//  Briefcase
//
//  Created by Michael Taylor on 19/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCConnectionDelegate.h"

extern NSString * kConnectionEstablished;
extern NSString * kConnectionTerminated;
extern NSString * kConnectionFailed;

@interface BCConnection : NSObject {
    NSString *		    myHostName;
    NSInteger		    myPort;
    NSString *		    myUsername;
    NSString *		    myPassword;
    id			    myUserData;
    NSNetService *	    myNetService;
    
    id <BCConnectionDelegate> myDelegate;
}

@property (readonly)		NSString *  hostName;
@property (nonatomic, retain)	NSString *  username;
@property (nonatomic, retain)	NSString *  password;
@property (nonatomic, retain)	id	    userData;
@property (readonly)		NSString *  protocol;
@property (readonly)		NSInteger   port;
@property (readonly)		BOOL	    isConnected;

@property (nonatomic, retain)	id <BCConnectionDelegate> delegate;


-(id)initWithNetService:(NSNetService*)service;

-(id)initWithHost:(NSString*)host 
	     port:(NSInteger)port;

-(BOOL)connect;
-(BOOL)loginWithUsername:(NSString*)username andPassword:(NSString*)password;
-(void)disconnect;

- (void)requestUsernameAndPassword:(KeychainItem*)item 
			    target:(id)object 
		   successSelector:(SEL)success_selector
		 cancelledSelector:(SEL)cancelled_selector
		      errorMessage:(NSString*)error_message;

// Utilities

- (void)notifyFailure;
- (void)notifyConnection;

@end
