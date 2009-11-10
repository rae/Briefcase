//
//  BriefcaseConnections.h
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCConnection.h"
#import "BriefcaseMessage.h"
#import "BriefcaseChannel.h"
#import "KeychainKeyPair.h"

@class AsyncSocket;
@class HMWorkerThread;

@interface BriefcaseConnection : BCConnection 
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

+ (HMWorkerThread*)briefcaseConnectionThread;

+ (KeychainKeyPair*)briefcaseKeyPair;

- (id)initWithSocket:(AsyncSocket*)socket;

- (BriefcaseChannel*)openChannelWithDelegate:(id <BriefcaseChannelDelegate>)delegate;

- (void)sendMessage:(BriefcaseMessage*)message;
- (void)listenForMessage;

@end
