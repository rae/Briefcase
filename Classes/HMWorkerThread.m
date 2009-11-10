//
//  FileThread.m
//  Briefcase
//
//  Created by Michael Taylor on 11/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "HMWorkerThread.h"
#include <unistd.h>

@implementation HMWorkerThread

@synthesize runLoop = myRunLoop;

- (void)main
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    myRunLoop = [[NSRunLoop currentRunLoop] retain];
    
    do
    {
        [myRunLoop runMode:NSDefaultRunLoopMode
		beforeDate:[NSDate distantFuture]];
	
	// TODO: Hack - why is this freaking out?
	usleep(10000);
	
	[pool release];
	pool = [[NSAutoreleasePool alloc] init];
    }
    while (TRUE);
    
    [myRunLoop release];
    
    [pool release];
}

- (void) dealloc
{
    [myRunLoop release];
    [super dealloc];
}

@end
