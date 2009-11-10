//
//  BlockingActionSheet.m
//  Briefcase
//
//  Created by Michael Taylor on 09-09-17.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import "BlockingActionSheet.h"

@implementation BlockingActionSheet

- (NSInteger)showInMainThreadInView:(UIView*)view
{
    myAnswer = -1;
    
    [self performSelectorOnMainThread:@selector(showInView:) withObject:view waitUntilDone:YES];
    
    // Lock my condition
    if (!myCondition)
	myCondition = [[NSCondition alloc] init];
    [myCondition lock];
    
    while (myAnswer < 0) 
    {
	[myCondition wait];
    }
    
    [myCondition unlock];
    
    return myAnswer;
}

- (NSInteger)showInMainThreadFromTabBar:(UITabBar*)tab_bar
{
    myAnswer = -1;
    
    [self performSelectorOnMainThread:@selector(showFromTabBar:) withObject:tab_bar waitUntilDone:YES];
    
    // Lock my condition
    if (!myCondition)
	myCondition = [[NSCondition alloc] init];
    [myCondition lock];
    
    while (myAnswer < 0) 
    {
	[myCondition wait];
    }
    
    [myCondition unlock];
    
    return myAnswer;    
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    [myCondition lock];
    myAnswer = buttonIndex;
    [myCondition signal];
    [myCondition unlock];
    [super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

@end

