//
//  BriefcaseApplications.h
//  Briefcase
//
//  Created by Michael Taylor on 28/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EventListener

- (void)processEvent:(UIEvent*)event;

@end

@interface BriefcaseApplication : UIApplication 
{
    id <EventListener>	myEventListener;
}

@property (nonatomic,retain) id <EventListener> eventListener;

@end
