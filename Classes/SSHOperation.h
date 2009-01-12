//
//  SSHOperation.h
//  Briefcase
//
//  Created by Michael Taylor on 05/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkOperation.h"

@class SSHConnection;

@interface SSHOperation : NetworkOperation {
    SSHConnection * myConnection;
    NSString *	    myHostname;
    NSString *	    myUsername;
    NSInteger	    myPort;    
}

- (id)initWithConnection:(SSHConnection*)connection;

- (id)initWithHost:(NSString*)host 
	  username:(NSString*)username 
	      port:(NSInteger)port;


// Utility functions

- (void)getIcon:(NSData**)icon andPreview:(NSData**)preview atPath:(NSString*)path;

@end
