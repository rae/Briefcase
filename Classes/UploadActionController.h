//
//  LocalFileBrowserController.h
//  Briefcase
//
//  Created by Michael Taylor on 20/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DownloadedFileBrowser;
@class FileActionController;
@class File;

@interface UploadActionController : NSObject {
    DownloadedFileBrowser *		myDownloadedFileBrowser;
    FileActionController *		myFileActionController;
    IBOutlet UINavigationController *	myNavigationController;
}

@property (readonly) UINavigationController * navigationController;

+ (UploadActionController*)sharedController;

- (id)init;

- (void)fileForAction:(File*)file;

@end
