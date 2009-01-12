//
//  BriefcaseConnectionController.h
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Connection.h"

@interface BriefcaseConnectionController : NSObject <ConnectionDelegate>
{
    NSMutableArray *	myConnections;
}

+ (BriefcaseConnectionController*)sharedController;

@end
