//
//  FreeSpaceController.h
//  Briefcase
//
//  Created by Michael Taylor on 09/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * kFreeSpaceChanged;

@interface FreeSpaceController : NSObject 
{
    long long	    myBaseFreeSpace;
    long long	    myCalculatedFreeSpace;
    long long	    myCalculatedUnreservedSpace;
    
    long long	    myBaseUsedSpace;
    long long	    myCalculatedUsedSpace;
    
    NSMutableSet *  myDownloads;
}

@property (nonatomic,readonly) long long freeSpace;
@property (nonatomic,readonly) long long unreservedSpace;
@property (nonatomic,readonly) long long usedSpace;

+ (FreeSpaceController*)sharedController;

@end
