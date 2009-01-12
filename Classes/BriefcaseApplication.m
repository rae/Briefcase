//
//  BriefcaseApplications.m
//  Briefcase
//
//  Created by Michael Taylor on 28/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BriefcaseApplication.h"

@implementation BriefcaseApplication

@synthesize eventListener = myEventListener;

- (void)sendEvent:(UIEvent *)event
{
    if (myEventListener)
	[myEventListener processEvent:event];
    
    [super sendEvent:event];
}

@end
