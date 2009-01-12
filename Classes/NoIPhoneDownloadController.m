//
//  NoIPhoneDownloadController.m
//  Briefcase
//
//  Created by Michael Taylor on 18/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "NoIPhoneDownloadController.h"
#import "GradientView.h"

@implementation NoIPhoneDownloadController

- (id)init
{
    if (self = [super initWithNibName:@"NoDownload" bundle:nil]) {
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

- (void)dealloc {
    [super dealloc];
}


@end
