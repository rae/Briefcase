//
//  untitled.h
//  Briefcase
//
//  Created by Michael Taylor on 27/12/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "HMWorkerThread.h"

extern NSString * kFileDatabaseWillFinalize;
extern NSString * kFileDatabaseCreated;

@interface Database : NSObject {
    sqlite3 *      myDatabase;
    HMWorkerThread * myDatabaseThread;
}

@property (nonatomic,readonly) sqlite3	    * sqliteDatabase;
@property (nonatomic,readonly) HMWorkerThread * thread;

+ (Database*)sharedDatabase;
+ (HMWorkerThread *)databaseThread;
+ (void)finalizeDatabase;

@end
