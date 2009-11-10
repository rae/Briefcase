//
//  ConnectionManager.m
//  Briefcase
//
//  Created by Michael Taylor on 19/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BCConnectionManager.h"
#import "SSHConnection.h"
#import "BriefcaseConnection.h"
#import "BCConnection.h"
#import "HMWorkerThread.h"

#include <resolv.h>

static BCConnectionManager *  theConnectionManager = nil;
static HMWorkerThread *	    theWorkerThread = nil;

NSString * kSSHProtocol = @"_ssh._tcp.";
NSString * kBriefcaseProtocol = @"_briefcase._tcp.";
NSString * kNetworkReachibilityChanged = @"Network Reachibility Changed";

static void NetworkReachabilityCallback(SCNetworkReachabilityRef target, 
					SCNetworkReachabilityFlags flags, void *info);
static void BonjourReachabilityCallback(SCNetworkReachabilityRef target, 
					SCNetworkReachabilityFlags flags, void *info);

@implementation BCConnectionManager

+ (BCConnectionManager*)sharedManager
{
    if (!theConnectionManager)
	theConnectionManager = [[BCConnectionManager alloc] init];
    return theConnectionManager;
}

- (id) init
{
    self = [super init];
    if (self != nil) {
	myConnections = [[NSMutableArray alloc] init];
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(connectionEstablished:) 
		       name:kConnectionEstablished object:nil];
	[center addObserver:self 
		   selector:@selector(connectionTerminated:) 
		       name:kConnectionEstablished object:nil];
	
	// Start our worker thread
	theWorkerThread = [[HMWorkerThread alloc] init];
	[theWorkerThread start];
	
	// Set up network reachibility query	    
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	myNetworkReachibility = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
	
	// Set up bonjour reachibility query
	struct sockaddr_in sin;        
        bzero(&sin, sizeof(sin));
        sin.sin_len = sizeof(sin);
        sin.sin_family = AF_INET;
        // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
        sin.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
        
        myBonjourReachibility = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&sin);
	
	[self performSelectorInBackground:@selector(_scheduleDefaultReachibilities) 
			       withObject:nil];
	
	
    }
    return self;
}

- (void)_scheduleDefaultReachibilities
{
    // Set up default reachibility query	
    
    CFRunLoopRef runLoop = [theWorkerThread.runLoop getCFRunLoop];
    while (!runLoop)
    {
	[NSThread sleepForTimeInterval:0.5];
	runLoop = [theWorkerThread.runLoop getCFRunLoop];
    }
    
    SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
    SCNetworkReachabilitySetCallback(myNetworkReachibility, NetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(myNetworkReachibility, runLoop, kCFRunLoopDefaultMode);
    
    SCNetworkReachabilitySetCallback(myBonjourReachibility, BonjourReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(myBonjourReachibility, runLoop, kCFRunLoopDefaultMode);
}

- (void) dealloc
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
    [myConnections release];
    [super dealloc];
}

- (void)connectionEstablished:(NSNotification*)notification
{
    [myConnections addObject:[notification object]];
}

- (void)connectionTerminated:(NSNotification*)notification
{
    [myConnections removeObject:[notification object]];
}

- (BCConnection*)connectForProtocol:(NSString*)protocol 
			 withHost:(NSString*)host 
			     port:(NSInteger)port
{
    BCConnection * result = nil;
    
    // Try to find an existing connection
    for (BCConnection * connection in myConnections)
    {
	if ([connection.hostName isEqualToString:host] &&
	    [connection.protocol isEqualToString:protocol] &&
	    connection.port == port)
	{
	    return connection;
	}
    }
    
    if ([protocol isEqualToString:kSSHProtocol])
	result = [[[SSHConnection alloc] initWithHost:host port:port] autorelease];
    else if ([protocol isEqualToString:kBriefcaseProtocol])
	result = [[[BriefcaseConnection alloc] initWithHost:host port:port] autorelease];
    else
	NSAssert(@"Unknown Protocol",FALSE);
    return result;
}

- (BCConnection*)connectForNetService:(NSNetService*)service
{
    BCConnection * result = nil;
    
    // Try to find an existing connection
    for (BCConnection * connection in myConnections)
    {
	if ([connection.hostName isEqualToString:[service hostName]] &&
	    [connection.protocol isEqualToString:[service type]] &&
	    connection.port == [service port])
	{
	    return connection;
	}
    }
    
    if ([[service type] isEqualToString:kSSHProtocol])
	result = [[[SSHConnection alloc] initWithNetService:service] autorelease];
    else if ([[service type] isEqualToString:kBriefcaseProtocol])
	result = [[[BriefcaseConnection alloc] initWithHost:[service hostName] port:[service port]] autorelease];
    else
	NSAssert(@"Unknown Protocol",FALSE);
    return result;
}

- (void)connectWhenReachableForProtocol:(NSString*)protocol 
			       withHost:(NSString*)host 
				   port:(NSInteger)port
{
    if (!host || ![host length]) return;
    
    NSArray * args = [[NSArray alloc] initWithObjects:protocol, host, 
		      [NSNumber numberWithInt:port], nil];
    [self performSelectorInBackground:@selector(_connectWhenReachable:) withObject:args];
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, 
				 SCNetworkReachabilityFlags flags, void *info)
{ 
    // The host is reachable
    NSArray * args = (NSArray*)info;
    NSString * protocol = [args objectAtIndex:0];
    NSString * host	= [args objectAtIndex:1];
    NSInteger port	= [(NSNumber*)[args objectAtIndex:2] intValue];
    
    BCConnection * connection;
    connection = [theConnectionManager connectForProtocol:protocol withHost:host port:port];
    [connection performSelectorOnMainThread:@selector(connect) withObject:nil
			      waitUntilDone:YES];
    
    [args release];
    
    CFRunLoopRef runLoop = [theWorkerThread.runLoop getCFRunLoop];
    SCNetworkReachabilityUnscheduleFromRunLoop(target, runLoop, kCFRunLoopDefaultMode);
}

static void NetworkReachabilityCallback(SCNetworkReachabilityRef target, 
					SCNetworkReachabilityFlags flags, void *info)
{ 
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kNetworkReachibilityChanged object:nil];
}

static void BonjourReachabilityCallback(SCNetworkReachabilityRef target, 
					SCNetworkReachabilityFlags flags, void *info)
{ 
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kNetworkReachibilityChanged object:nil];
}

- (void)_connectWhenReachable:(NSArray*)args
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSString * host	= [args objectAtIndex:1];
    
    SCNetworkReachabilityRef reachability;
    reachability = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
    
    CFRunLoopRef runLoop = [theWorkerThread.runLoop getCFRunLoop];
    while (!runLoop)
    {
	[NSThread sleepForTimeInterval:0.5];
	runLoop = [theWorkerThread.runLoop getCFRunLoop];
    }
    
    NSAssert(runLoop,@"No worker runloop!!");
    
    SCNetworkReachabilityContext context = {0, [args retain], NULL, NULL, NULL};
    SCNetworkReachabilitySetCallback(reachability, ReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(reachability, runLoop, kCFRunLoopDefaultMode);
    
    [pool release];
}

- (BOOL)networkAvailable
{       
#if TARGET_IPHONE_SIMULATOR
    return TRUE;
#else
    SCNetworkReachabilityFlags flags;
    BOOL got_flags = SCNetworkReachabilityGetFlags(myNetworkReachibility, &flags);
    
    if (!got_flags) 
        return NO;
        
    BOOL isReachable = flags & kSCNetworkReachabilityFlagsReachable;
    
    // This flag indicates that the specified nodename or address can
    // be reached using the current network configuration, but a
    // connection must first be established.
    //
    // If the flag is false, we don't have a connection. But because CFNetwork
    // automatically attempts to bring up a WWAN connection, if the WWAN reachability
    // flag is present, a connection is not required.
    BOOL no_connection_required = !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN))
	no_connection_required = YES;
    
    return isReachable && no_connection_required;
#endif
}

- (BOOL)wifiAvailable
{       
#if TARGET_IPHONE_SIMULATOR
    return TRUE;
#else
    SCNetworkReachabilityFlags flags;
    BOOL got_flags = SCNetworkReachabilityGetFlags(myNetworkReachibility, &flags);
    
    if (!got_flags) 
        return NO;
    
    BOOL isReachable = flags & kSCNetworkReachabilityFlagsReachable;
    
    // This flag indicates that the specified nodename or address can
    // be reached using the current network configuration, but a
    // connection must first be established.
    BOOL no_connection_required = !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
    
    // If we need to bring up a WWAN connection, then we're not on WiFi
    BOOL not_wwan = !(flags & kSCNetworkReachabilityFlagsIsWWAN);
    
    return isReachable && no_connection_required && not_wwan;
#endif
}

- (BOOL)bonjourAvailable
{
#if TARGET_IPHONE_SIMULATOR
    return TRUE;
#else
    SCNetworkReachabilityFlags flags;
    BOOL got_flags = SCNetworkReachabilityGetFlags(myBonjourReachibility, &flags);
    
    if (!got_flags) 
        return NO;
    
    BOOL isReachable = flags & kSCNetworkReachabilityFlagsReachable;
    
    // This flag indicates that the specified nodename or address can
    // be reached using the current network configuration, but a
    // connection must first be established.
    //
    // If the flag is false, we don't have a connection. But because CFNetwork
    // automatically attempts to bring up a WWAN connection, if the WWAN reachability
    // flag is present, a connection is not required.
    BOOL no_connection_required = !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN))
	no_connection_required = YES;
        
    return isReachable && no_connection_required && (flags & kSCNetworkReachabilityFlagsIsDirect);
#endif
}

@end

