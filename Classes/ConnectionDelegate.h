//
//  ConnectionDelegate.h
//  Briefcase
//
//  Created by Michael Taylor on 19/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

@class KeychainItem;

@class Connection;

@protocol ConnectionDelegate

- (void)connectionEstablished:(Connection*)connection;
- (void)connectionTerminated:(Connection*)connection;
- (void)connectionFailed:(Connection*)connection;

- (int)allowConnectionToHost:(NSString*)host withHash:(NSData*)hash;

- (BOOL)warnAboutChangedHash;
- (void)displayLoginFailed;

- (void)requestUsernameAndPassword:(KeychainItem*)item 
			    target:(id)object 
		   successSelector:(SEL)success_selector
		 cancelledSelector:(SEL)cancelled_selector
		      errorMessage:(NSString*)error_message;

@end
