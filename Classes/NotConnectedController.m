//
//  NotConnectedView.m
//  Briefcase
//
//  Created by Michael Taylor on 09/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "NotConnectedController.h"
#import "GradientView.h"

@implementation NotConnectedController

- (id)init
{
    if (self = [super initWithNibName:@"NotConnectedView" bundle:nil]) {
	self.navigationItem.hidesBackButton = YES;
	self.navigationItem.title = NSLocalizedString(@"Download", @"Title for screen that allows you to download files");
    }
    return self;
}

 - (void)loadView 
{
    [super loadView];
    
    GradientView * view = (GradientView*)self.view;
    view.gradientCenter = myImageView.center;
}

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
 - (void)viewDidLoad {
 }
 */


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


@end
