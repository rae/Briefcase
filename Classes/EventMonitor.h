//
//  EventMonitor.h
//  Briefcase
//
//  Created by Michael Taylor on 28/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BriefcaseApplication.h"

@protocol EventMonitorDelegate

- (void)didSingleTap;
- (void)didTouchMove;
- (void)didIdle;

@end


@interface EventMonitor : NSObject <EventListener> {
    UIView *			myViewToMonitor;
    id <EventMonitorDelegate>	myDelegate;
    NSTimeInterval		myIdleTime;
}

@property (nonatomic,retain) UIView *			viewToMonitor;
@property (nonatomic,assign) id <EventMonitorDelegate>	delegate;
@property (nonatomic,assign) NSTimeInterval		idleEventDelay;
@property (nonatomic,readonly) BOOL			monitoring;

- (void)beginMonitoring;
- (void)endMonitoring;

@end
