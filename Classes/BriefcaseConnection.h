//
//  BriefcaseConnections.h
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Connection.h"
#import "BriefcaseMessage.h"
#import "BriefcaseChannel.h"
#import "KeychainKeyPair.h"

@class AsyncSocket;
@class WorkerThread;

@interface BriefcaseConnection : Connection 
{
    AsyncSocket *	    mySocket;
    NSMutableDictionary	*   myMessagesByTag;
    NSMutableDictionary *   myChannelsByID;
    
    BOOL		    myIsAuthenticated;
    BOOL		    myIsInitiatingConnection;
    
    BOOL		    myIsAwaitingHeader;
    NSMutableArray *	    myQueuedHeaderReads;
    
    NSData *		    mySessionKey;
}

@property (assign) BOOL		isAuthenticated;
@property (retain) NSData *	sessionKey;

+ (WorkerThread*)briefcaseConnectionThread;

+ (KeychainKeyPair*)briefcaseKeyPair;

- (id)initWithSocket:(AsyncSocket*)socket;

- (BriefcaseChannel*)openChannelWithDelegate:(id <BriefcaseChannelDelegate>)delegate;

- (void)sendMessage:(BriefcaseMessage*)message;
- (void)listenForMessage;

@end
