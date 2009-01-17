//
//  SSHOperation.m
//  Briefcase
//
//  Created by Michael Taylor on 05/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SSHOperation.h"

#import "Connection.h"
#import "ConnectionManager.h"
#import "SystemInformation.h"
#import "Utilities.h"

#define kIconCommandFormat @"bzip2 -d -c|python -c \"import sys;eval(compile(sys.stdin.read(),'<stdin>','exec'))\" '%@'"

@implementation SSHOperation

- (id)initWithConnection:(SSHConnection*)connection
{
    self = [super init];
    if (self != nil) {
	myConnection = [connection retain];
	myHostname = [connection.hostName retain];
	myUsername = [connection.username retain];
	myPort = connection.port;
    }
    return self;
}

- (id)initWithHost:(NSString*)host 
	  username:(NSString*)username 
	      port:(NSInteger)port
{
    self = [super init];
    if (self != nil) {
	myConnection = nil;
	myHostname = [host retain];
	myUsername = [username retain];
	myPort = port;
	
	// Ask the connection manager to start a connection
	[[ConnectionManager sharedManager] connectWhenReachableForProtocol:kSSHProtocol 
								  withHost:myHostname 
								      port:port];
	
	// Watch for the connection
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(_connectionEstablished:) 
		       name:kConnectionEstablished object:nil];
    }
    return self;
}

- (BOOL)isReady
{
    return [super isReady] && (myConnection != nil);
}

- (void) dealloc
{
    [myHostname release];
    [myUsername release];
    [myConnection release];
    [super dealloc];
}

- (void)_connectionEstablished:(NSNotification*)notification
{
    // See if this is the connection we are waiting for
    Connection * connection = [notification object];
    if ([connection.hostName isEqualToString:myHostname] &&
	[connection.username isEqualToString:myUsername] &&
	connection.port == myPort)
    {
	// This is the one!
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center removeObserver:self];
	
	[self willChangeValueForKey:@"isReady"];
	myConnection = [connection retain];
	[self didChangeValueForKey:@"isReady"];
    }
}

- (void)getIcon:(NSData**)icon andPreview:(NSData**)preview atPath:(NSString*)path;
{
    *icon = nil;
    *preview = nil;
    
    // Check if we are connected to a Mac running Leopard or better.
    // If so, try to grab an icon
    SystemInformation * info = myConnection.userData;
    if (info && [info isConnectedToMac] && [info darwinVersion] >= 9.0)
    {
	NSData * file_data = nil;
	NSData * icon_helper = [Utilities getResourceData:@"thumbnail_grab.py.bz2"];
	NSString * command = [NSString stringWithFormat:kIconCommandFormat, path];
	@try 
	{
	    file_data = [myConnection executeCommand:command withInput:icon_helper];
	    NSDictionary * dict = [NSKeyedUnarchiver unarchiveObjectWithData:file_data];
	    if (dict)
	    {
		*icon = [dict objectForKey:@"icon"];
		*preview = [dict objectForKey:@"preview"];
	    }
	}
	@catch (NSException*) 
	{
	    NSLog(@"Could not grab icon for remote file");
	    
	    if (!myConnection.isConnected)
		// If we've lost the connection, then re-throw the
		// exception
		@throw;
	}
    }
}

@end
