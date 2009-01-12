//
//  ModalController.m
//  Briefcase
//
//  Created by Michael Taylor on 29/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ModalController.h"

#define kRunloopCheckInterval 0.1

@implementation ModalController

@synthesize target = myTarget;
@synthesize action = myAction;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)dealloc 
{
    [myTarget release];
    [super dealloc];
}

- (BOOL)presentModalView:(UINavigationController*)nav_controller
{
    myNavigationController = [nav_controller retain];
    
    self.navigationItem.leftBarButtonItem = 
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
						  target:self 
						  action:@selector(cancelled)];

    [nav_controller presentModalViewController:self animated:YES];
    
    if (myTarget && myAction)
	// Short circuit here.  We'll handle cleanup in "done"
	return TRUE;
    
    // If we don't have a target and a selector, then we'll block
    // and drive an event loop until we've got our answer
    NSRunLoop * current_loop = [[NSRunLoop currentRunLoop] retain];
    myState = kWaiting;
    
    while (myState == kWaiting) 
    {
	NSDate * until = [NSDate dateWithTimeIntervalSinceNow:kRunloopCheckInterval];
	[current_loop runMode:NSDefaultRunLoopMode beforeDate:until];
    }
    [current_loop release];
    
    [myNavigationController dismissModalViewControllerAnimated:YES];
        
    return myState == kDone;
}

- (void)done
{
    myState = kDone;
    
    [myNavigationController dismissModalViewControllerAnimated:YES];
    [myNavigationController release];
    myNavigationController = nil;
}

- (void)viewDidLoad
{
    [myNavigationBar pushNavigationItem:self.navigationItem animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (myTarget && myAction)
	[myTarget performSelector:myAction withObject:self];
}

- (void)cancelled
{
    myState = kCancelled;
    [myNavigationController dismissModalViewControllerAnimated:YES];
}

- (BOOL)wasCancelled
{
    return myState == kCancelled;
}

@end
