//
//  ConnectionManager.h
//  Briefcase
//
//  Created by Michael Taylor on 19/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SCNetworkReachability.h>

extern NSString * kSSHProtocol;
extern NSString * kBriefcaseProtocol;
extern NSString * kNetworkReachibilityChanged;

@class BCConnection;
@class HMWorkerThread;

@interface BCConnectionManager : NSObject {
    NSMutableSet *		myConnections;
    SCNetworkReachabilityRef	myNetworkReachibility;
    SCNetworkReachabilityRef	myBonjourReachibility;
}

@property (nonatomic,readonly) BOOL networkAvailable;
@property (nonatomic,readonly) BOOL wifiAvailable;
@property (nonatomic,readonly) BOOL bonjourAvailable;

+ (BCConnectionManager*)sharedManager;

- (BCConnection*)connectForProtocol:(NSString*)protocol 
			 withHost:(NSString*)host 
			     port:(NSInteger)port;

- (BCConnection*)connectForNetService:(NSNetService*)service;

- (void)connectWhenReachableForProtocol:(NSString*)protocol 
					 withHost:(NSString*)host 
					 port:(NSInteger)port;

@end
