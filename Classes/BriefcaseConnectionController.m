//
//  BriefcaseConnectionController.m
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BriefcaseConnectionController.h"

#import "AsyncSocket.h"
#import "BriefcaseConnection.h"
#import "BlockingAlert.h"
#import "WorkerThread.h"

static BriefcaseConnectionController * theBriefcaseConnectionController = nil;

@implementation BriefcaseConnectionController

+ (BriefcaseConnectionController*)sharedController
{
    if (!theBriefcaseConnectionController)
	theBriefcaseConnectionController = [[BriefcaseConnectionController alloc] init];
    return theBriefcaseConnectionController;
}

- (id) init
{
    self = [super init];
    if (self != nil) 
    {
	myListenSocket = [[AsyncSocket alloc] initWithDelegate:self];
	myConnections = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)startServer
{
    // Make sure our worker thread is running
    WorkerThread * thread = [BriefcaseConnection briefcaseConnectionThread];
    
    // Advertise with Bonjour
    myNetService = [[NSNetService alloc] initWithDomain:@"local." 
						   type:@"_briefcase._tcp." 
						   name:[[UIDevice currentDevice] name] 
						   port:kBriefcaseServerPort];
    [myNetService scheduleInRunLoop:thread.runLoop forMode:NSDefaultRunLoopMode];
    [myNetService publish];
    
    [self performSelector:@selector(_startServer)
		 onThread:thread 
	       withObject:nil 
	    waitUntilDone:NO];
}

- (void)_startServer
{
    // Start listening
    NSError *error = nil;
    if(![myListenSocket acceptOnPort:kBriefcaseServerPort error:&error])
    {
	NSString * format = NSLocalizedString(@"Briefcase server failed to start: %@", "Message to user when starting the server fails");
	
	UIAlertView * server_alert;
	server_alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Server Error", @"Title for dialog telling the user that the server failed to start") 
						  message:[NSString stringWithFormat:format]
						 delegate:self 
					cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok button label")
					otherButtonTitles:nil];
	
	[server_alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
	[server_alert release];
	return;
    }
}

-(void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    BriefcaseConnection * new_connection = [[BriefcaseConnection alloc] initWithSocket:newSocket];
    new_connection.delegate = self;
    [myConnections addObject:new_connection];
}

-(NSRunLoop *)onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket
{
    return [[BriefcaseConnection briefcaseConnectionThread] runLoop];
}

- (void)connectionReady:(BriefcaseConnection*)connection
{
    // A connection we accepted is now ready for use.  Look for the 
    // authentication request
    [connection listenForMessage];
}

- (void)messageReceived:(BriefcaseMessage*)message onConnection:(BriefcaseConnection*)connection
{
    if (message.type == kConnectionRequest)
    {
	if (connection.isAuthenticated)
	{
	    // Error, this connection has already been authenticated!!
	    connection.delegate = nil;
	    [connection disconnect];
	    return;
	}
	
	BlockingAlert * server_alert;
	
	NSString * message_format = NSLocalizedString(@"Do you wish to receive files from \"%@\"? (Quitting Briefcase will cancel transfer.) Accept files?", @"Message asking the user if they want to receive a transfer from another iPhone and advising them how to cancel the connection");
	
	server_alert = [[BlockingAlert alloc] initWithTitle:NSLocalizedString(@"Connection Request", @"Title for dialog asking user if they wish to accept a connection from another iPhone") 
						    message:[NSString stringWithFormat:message_format, message.payloadString]
						   delegate:self 
					  cancelButtonTitle:NSLocalizedString(@"No", @"No, refuse connection")
					  otherButtonTitles:NSLocalizedString(@"Yes", @"Yes, accept connection"), nil];
	
	NSInteger answer = [server_alert showInMainThread];
	
	if (answer == 0)
	{
	    connection.delegate = nil;
	    [connection disconnect];
	}
	else
	{
	    connection.isAuthenticated = YES;
	    
	    BriefcaseMessage * accepted_message = [BriefcaseMessage messageWithType:kConnectionAllowed tag:kServerTag];
	    [connection sendMessage:accepted_message];
	}
    }
    else
    {
	if (!connection.isAuthenticated)
	{
	    // Someone has tried to send a message when they are not
	    // authenticated.  Terminate with extreme prejudice
	    connection.delegate = nil;
	    [connection disconnect];
	    return;
	}
	
	NSAssert(FALSE,@"We don't support other messages yet!");
    }
}

#pragma mark ConnectionDelegate methods

- (void)connectionEstablished
{
    
}

- (void)connectionTerminated
{
    
}

- (void)connectionFailed
{
    
}

- (int)allowConnectionToHost:(NSString*)host withHash:(NSData*)hash
{
    return 0;
}

- (BOOL)warnAboutChangedHash
{
    NSAssert(FALSE,@"Should not be called");
    return NO;
}

- (void)displayLoginFailed
{
    
}

- (void)requestUsernameAndPassword:(KeychainItem*)item 
			    target:(id)object 
		   successSelector:(SEL)success_selector
		 cancelledSelector:(SEL)cancelled_selector
{
    
}

@end
