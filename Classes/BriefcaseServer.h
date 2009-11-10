//
//  BriefcaseServer.h
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCConnection.h"

@class KeychainKeyPair;
@class AsyncSocket;

#define kBriefcaseServerPort 2226

@interface BriefcaseServer : NSObject <BCConnectionDelegate>
{
    AsyncSocket *	    myListenSocket;
    NSNetService *	    myNetService;
    
    NSMutableDictionary *   myDownloadsByChannelID;
    KeychainKeyPair *	    myKeychainPair;
}

+ (BriefcaseServer*)sharedController;

- (void)startServer;

@end
