//
//  EventMonitor.m
//  Briefcase
//
//  Created by Michael Taylor on 28/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "EventMonitor.h"

const NSTimeInterval kDoubleTapInterval = 0.25;

@implementation EventMonitor

@synthesize viewToMonitor = myViewToMonitor;
@synthesize delegate = myDelegate;

- (id)init
{
    myIdleTime = 0.0;
    return [super init];
}

- (void) dealloc
{        
    [myViewToMonitor release];
    [super dealloc];
}


- (void)resetIdleTimer
{
    [NSObject cancelPreviousPerformRequestsWithTarget:myDelegate 
					     selector:@selector(didIdle) 
					       object:nil];
    
    if (self.monitoring && myIdleTime > 0.0)
	[(NSObject*)myDelegate performSelector:@selector(didIdle) 
				    withObject:nil 
				    afterDelay:myIdleTime];
}

- (void)processEvent:(UIEvent*)event
{
    NSSet * touches = [event allTouches];
    if (touches && [touches count] > 0)
	[self resetIdleTimer];
    
    touches = [event touchesForView:myViewToMonitor];
    
    if ([touches count] > 1) return;

    UITouch * touch = [touches anyObject];
    
    if (touch.phase == UITouchPhaseEnded && touch.tapCount == 1)
	// Start to call the single tap method
	[(NSObject*)myDelegate performSelector:@selector(didSingleTap) 
				    withObject:nil 
				    afterDelay:kDoubleTapInterval];
    else if (touch.phase == UITouchPhaseBegan && touch.tapCount > 1)
	// Cancel previous calls
	[NSObject cancelPreviousPerformRequestsWithTarget:myDelegate];
    else if (touch.phase == UITouchPhaseMoved)
	[(NSObject*)myDelegate performSelector:@selector(didTouchMove) 
				    withObject:nil 
				    afterDelay:kDoubleTapInterval];
	
}

- (void)beginMonitoring
{
    BriefcaseApplication * app = (BriefcaseApplication*)[UIApplication sharedApplication];
    app.eventListener = self;
    [self resetIdleTimer];
}

- (void)endMonitoring
{
    BriefcaseApplication * app = (BriefcaseApplication*)[UIApplication sharedApplication];
    app.eventListener = nil;
    [self resetIdleTimer];
}

#pragma mark Properties

- (NSTimeInterval)idleEventDelay
{
    return myIdleTime;
}

- (void)setIdleEventDelay:(NSTimeInterval)delay
{
    myIdleTime = delay;
    [self resetIdleTimer];
}

- (BOOL)monitoring
{
    BriefcaseApplication * app = (BriefcaseApplication*)[UIApplication sharedApplication];
    return app.eventListener == self;
}

@end
