//
//  LocalFileBrowserController.m
//  Briefcase
//
//  Created by Michael Taylor on 20/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "UploadActionController.h"
#import "DownloadedFileBrowser.h"
#import "FileActionController.h"
#import "Utilities.h"

static UploadActionController * theUploadController;

@implementation UploadActionController

@synthesize navigationController = myNavigationController;

+ (UploadActionController*)sharedController
{
    if (!theUploadController)
	theUploadController = [[UploadActionController alloc] init];
    return theUploadController;
}

- (id)init
{
    if (self = [super init])
    {
	myFileActionController = [[FileActionController alloc] init];
	
	myDownloadedFileBrowser = [[DownloadedFileBrowser alloc] initWithUploadController:self localPath:@""];
	myNavigationController = [[UINavigationController alloc] initWithRootViewController:myDownloadedFileBrowser];
    }
    
    return self;
}

- (void)loadViews
{
    [myNavigationController pushViewController:myDownloadedFileBrowser animated:NO];
}

- (void)fileForAction:(File*)file
{
    // Push a view
    myFileActionController.file = file;
    [myNavigationController pushViewController:myFileActionController animated:YES];
}

@end
