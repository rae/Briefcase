//
//  DualNavigationViewController.m
//  navtest
//
//  Created by Michael Taylor on 14/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "DualViewController.h"

#define kTransitionDuration 0.35

@implementation DualViewController

@synthesize mainController = myMainController;

- (id)initWithViewController:(UIViewController *)mainViewController
{
    if (self = [super initWithNibName:nil bundle:nil]) 
    {
	myMainController = [mainViewController retain];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (myAlternateViewController)
	[myAlternateViewController viewWillAppear:animated];
    else
	[myMainController viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (myAlternateViewController)
	[myAlternateViewController viewDidAppear:animated];
    else
	[myMainController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (myAlternateViewController)
	[myAlternateViewController viewWillDisappear:animated];
    else
	[myMainController viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (myAlternateViewController)
	[myAlternateViewController viewDidDisappear:animated];
    else
	[myMainController viewDidDisappear:animated];
}

- (void)loadView 
{
    NSAssert(myMainController,@"Null main view controller");
    
    self.view = [[UIView alloc] init];
    UIScreen * screen = [UIScreen mainScreen];
    self.view.frame = screen.bounds;
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | 
				 UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;
    
    [self.view addSubview:myMainController.view];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[super dealloc];
}

- (void)pushAlternateViewController:(UIViewController *)viewController
{
    myAlternateViewController = [viewController retain];
        
    // Put the new view out to the right side
    CGRect frame = self.view.frame;
    frame.origin.x = frame.size.width;
    viewController.view.frame = frame;
    
    [viewController viewWillAppear:YES];
    [myMainController viewWillDisappear:YES];
    
    // Add the view as a subview
    [self.view addSubview:viewController.view];
    
    [UIView beginAnimations:@"Dual view push" context:NULL];
    
    [UIView setAnimationDuration:kTransitionDuration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(pushFinished)];
    
    // Move the new view into position
    viewController.view.frame = self.view.frame;
    
    frame = myMainController.view.frame;
    frame.origin.x = -frame.size.width;
    myMainController.view.frame = frame;
    
    [UIView commitAnimations];
}

- (void)pushFinished
{
    [myAlternateViewController viewDidAppear:YES];
    [myMainController viewDidDisappear:YES];
}

- (void)popAlternateViewController
{
    CGRect frame;
    
    [myAlternateViewController viewWillDisappear:YES];
    [myMainController viewWillAppear:YES];
    
    [UIView beginAnimations:@"Dual view pop" context:NULL];
    
    [UIView setAnimationDuration:kTransitionDuration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(popDone)];
    
    // Bring the navigation view controller back in
    frame = myMainController.view.frame;
    frame.origin.x = 0;
    myMainController.view.frame = frame;
    
    // Send the top view out to the right
    frame = myAlternateViewController.view.frame;
    frame.origin.x = frame.size.width;
    myAlternateViewController.view.frame = frame;
    
    [UIView commitAnimations];
}

- (void)popDone
{
    [myAlternateViewController.view removeFromSuperview];
    [myAlternateViewController viewDidDisappear:YES];
    [myAlternateViewController release];
    
    myAlternateViewController = nil;
    [myMainController viewDidAppear:YES];
}

@end
