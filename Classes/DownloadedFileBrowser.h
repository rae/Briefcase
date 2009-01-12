//
//  DownloadedFileBrowser.h
//  Briefcase
//
//  Created by Michael Taylor on 20/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UploadActionController;

@interface DownloadedFileBrowser : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate> 
{
    IBOutlet UITableView *	myTableView;
    IBOutlet UISearchBar *	mySearchBar;
    UIBarButtonItem *		mySearchButton;
    NSArray *			myDirectoryEntries;
    UploadActionController *	myUploadController;
    NSString *			myLocalPath;
}

- (id)initWithUploadController:(UploadActionController*)controller localPath:(NSString*)path;

- (void)refreshDownloadList;

@end
