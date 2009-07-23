//
//  Connection.m
//  Briefcase
//
//  Created by Michael Taylor on 19/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//
#import "HeyMac.h"
#import "Connection.h"

NSString * kConnectionEstablished = @"connection established";
NSString * kConnectionTerminated = @"connection terminated";
NSString * kConnectionFailed = @"connection failed";

@implementation Connection

@dynamic protocol;

@synthesize hostName = myHostName;
@synthesize username = myUsername;
@synthesize password = myPassword;
@synthesize userData = myUserData;
@synthesize delegate = myDelegate;
@synthesize port     = myPort;


-(id)initWithNetService:(NSNetService*)service
{
    if (self = [super init])
    {
	myHostName = [[service hostName] retain];
	myPort = [service port];
	myUsername = @"";
	myPassword = @"";
	myNetService = [service retain];
    }
    return self;
}

-(id)initWithHost:(NSString*)host 
	     port:(NSInteger)port 
{
    if (self = [super init])
    {
	myHostName = [host retain];
	myPort = port;
	myUsername = @"";
	myPassword = @"";
	myNetService = nil;
    }
    return self;
}

- (void) dealloc
{
    [myHostName release];
    [myNetService release];
    [myUsername release];
    [myPassword release];
    [super dealloc];
}


-(BOOL)isConnected
{
    NSAssert(@"Abstract method called",FALSE);
    return FALSE;
}

-(BOOL)connect
{
    NSAssert(@"Abstract method called",FALSE);
    return FALSE;
}
-(BOOL)loginWithUsername:(NSString*)username andPassword:(NSString*)password
{
    NSAssert(@"Abstract method called",FALSE);
    return FALSE;
}
-(void)disconnect
{
    NSAssert(@"Abstract method called",FALSE);
}


- (void)requestUsernameAndPassword:(KeychainItem*)item 
			    target:(id)object 
		   successSelector:(SEL)success_selector
		 cancelledSelector:(SEL)cancelled_selector
		      errorMessage:(NSString*)error_message
{
    HMAssert([NSThread isMainThread],@"Must call request on main thread");
    [myDelegate requestUsernameAndPassword:item 
				    target:object
			   successSelector:success_selector
			 cancelledSelector:cancelled_selector
			      errorMessage:error_message];
}

- (void)notifyFailure
{
    if (myDelegate)
	[myDelegate connectionFailed:self];
    
    NSNotificationCenter * notification_center = [NSNotificationCenter defaultCenter];
    [notification_center postNotificationName:kConnectionFailed object:self];
}

- (void)notifyConnected
//
// Post notification of the establishment of a connection
//
{
    NSNotificationCenter * notification_center = [NSNotificationCenter defaultCenter];
    [notification_center postNotificationName:kConnectionEstablished object:self];
}

@end
