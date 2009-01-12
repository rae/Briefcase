//
//  SystemInfoManager.h
//  Briefcase
//
//  Created by Michael Taylor on 01/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSHConnection.h"

#define kSystemInfoChanged @"system info changed"

@interface SystemInformation : NSObject {
    SSHConnection *	    myConnection;
    NSMutableArray *	    mySystemData;
    BOOL		    myIsConnected;
    double		    myDarwinVersion;
    NSString *		    myModel;
    NSString *		    myTempDir;
} 

@property (readonly) BOOL	isConnected;
@property (readonly) BOOL	isConnectedToMac;
@property (readonly) double	darwinVersion;
@property (readonly) NSString *	macModel;
@property (readonly) NSString * tempDir;

-(id)initWithConnection:(SSHConnection*)connection;

-(NSUInteger)itemCount;
-(NSString*)descriptionForItemAtIndex:(NSUInteger)index;
-(NSString*)valueForItemAtIndex:(NSUInteger)index;

//Private

-(void)_queryOSXInfoOnConnection:(SSHConnection*)connection;
-(void)_notifyObservers;


@end
