//
//  HMCrashHandler.h
//  Briefcase
//
//  Created by Michael Taylor on 09-11-10.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef NDEBUG
#define HMCrashHandler              HMNetworkMonitor
#define pingServer                  checkNetworkAvailability
#define isPirated                   packetChecksum
#define handlePendingCrashReports   initiateConnection
#endif 

@interface HMCrashHandler : NSObject {
    
}

+ (HMCrashHandler*)sharedHandler;

- (void)pingServer;
- (void)handlePendingCrashReports;

@end
