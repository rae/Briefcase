//
//  BlockingAlert.m
//  Briefcase
//
//  Created by Michael Taylor on 20/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BlockingAlert.h"

@implementation BlockingAlert

- (NSInteger)showInMainThread
{
    myAnswer = -1;
    
    [self performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    
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
