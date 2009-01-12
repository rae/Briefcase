//
//  CommandOperation.m
//  Briefcase
//
//  Created by Michael Taylor on 03/06/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SSHCommandOperation.h"
#import "SSHConnection.h"
#import "ConnectionController.h"

@implementation SSHCommandOperation

@synthesize commandInput = myCommandInput;

-(id)initWithCommand:(NSString*)command connection:(Connection*)connection
{
    myCommand = [command retain];
    myConnection = [connection retain];
    myCommandInput = nil;
    return [super init];
}

- (void) dealloc
{
    [myCommand release];
    [myConnection release];
    [super dealloc];
}

-(void)main
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSData * result = nil;
    
    [self beginTask:NSLocalizedString(@"Running remote command", @"Log message when an upload begins")];
    
    ConnectionController * connection_controller;
    connection_controller = [ConnectionController sharedController];
    if (!connection_controller.currentConnection)
	return;
    
    SSHConnection * ssh_connection = (SSHConnection*)connection_controller.currentConnection;
        
    @try 
    {
	result = [ssh_connection executeCommand:myCommand withInput:myCommandInput];
	[self endTaskWithResult:result];
    }
    @catch (NSException *exception) 
    {
	NSLog(@"main: Caught %@: %@", [exception name], [exception  reason]);
	[self endTaskWithError:[exception reason]];
    }
    [pool release];
}

- (NSString*)title
{
    return NSLocalizedString(@"Running Remote Command", @"Label shown in activity view describing the operation");
}

- (NSString*)description
{
    return @"";
}

@end
