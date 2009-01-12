//
//  FileActionController.h
//  Briefcase
//
//  Created by Michael Taylor on 20/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FileInfoActions;
@class FileAction;
@class File;
@class FileType;
@class FileInfoCell;
@class Connection;
@class ConnectForOptionsCell;

@interface FileActionController : UIViewController <UITableViewDelegate, UITableViewDataSource> 
{
    UITableView *	    myTableView;
    
    File *		    myFile;
    FileType *		    myFileType;
    
    NSArray *		    myFixedUploadActions;
    NSMutableArray *	    myCustomUploadActions;
    NSArray *		    myFileSpecificActions;
    NSInteger		    myCustomUploadEditIndex;
    
    FileInfoCell *	    myFileInfoCell;
    ConnectForOptionsCell * myConnectForInfoCell;
    
    Connection *	    myConnection;
    BOOL		    myIsBriefcaseConnection;
    
    NSCountedSet *	    myInProgressIdentifiers;
}

@property (retain,nonatomic) File * file;

- (void)launchAction:(FileAction*)action;

@end
