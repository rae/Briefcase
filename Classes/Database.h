//
//  untitled.h
//  Briefcase
//
//  Created by Michael Taylor on 27/12/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "WorkerThread.h"

extern NSString * kFileDatabaseWillFinalize;
extern NSString * kFileDatabaseCreated;

@interface Database : NSObject {

}

+ (sqlite3 *)sharedDatabase;
+ (WorkerThread *)databaseThread;
+ (void)finalizeDatabase;

@end
