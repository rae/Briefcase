//
//  BookmarkListController.h
//  Briefcase
//
//  Created by Michael Taylor on 16/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"

@class File;

@protocol BookmarkListControllerDelegate

@property (nonatomic,assign) LongPoint documentPosition;

@end

@interface BookmarkListController : UIViewController <UITableViewDelegate, UITableViewDataSource> 
{
    IBOutlet UITableView *	myTableView;
    IBOutlet UINavigationBar *	myNavigationBar;
    IBOutlet UIToolbar *	myToolbar;
    
    UIBarButtonItem *		myDoneButton;
    UIBarButtonItem *		myEditButton;
    UIBarButtonItem *		myEditDoneButton;
    
    File *			myFile;
    NSMutableArray *		myBookmarks;
    id <BookmarkListControllerDelegate> myDelegate;
}

@property (nonatomic,copy)	NSArray * bookmarks;
@property (nonatomic,retain)	id <BookmarkListControllerDelegate> delegate;

- (id)initWithFile:(File*)file;

- (IBAction) doEdit;
- (IBAction) doneEdit;

@end
