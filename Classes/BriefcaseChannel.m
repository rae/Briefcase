//
//  BriefcaseChannel.m
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BriefcaseChannel.h"
#import "BriefcaseConnection.h"
#import "BriefcaseMessage.h"

@implementation BriefcaseChannel

@synthesize channelID = myChannelID;

- (id)initWithConnection:(BriefcaseConnection*)connection 
		delegate:(id <BriefcaseChannelDelegate>)delegate
{
    self = [super init];
    if (self != nil) 
    {   
	myChannelID = [[NSDate date] timeIntervalSince1970];
	myConnection = [connection retain];
	myDelegate = [(NSObject*)delegate retain];
    }
    return self;
}

- (void) dealloc
{
    [myConnection release];
    [(NSObject*)myDelegate release];
    [super dealloc];
}

- (void)sendMessage:(BriefcaseMessage*)message
{
    message.channelID = myChannelID;
    [myConnection sendMessage:message];
    
    // Read response
    [myConnection listenForMessage];
}

- (void)processMessage:(BriefcaseMessage*)message
{
    if (myDelegate)
	[myDelegate channelResponseRecieved:message];
}

@end
