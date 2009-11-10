//
//  FileActionController.h
//  Briefcase
//
//  Created by Michael Taylor on 20/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#import "TableSection.h"

@class FileInfoActions;
@class FileAction;
@class File;
@class FileType;
@class FileInfoCell;
@class BCConnection;
@class ConnectForOptionsCell;
@class SectionedTable;

@interface FileActionController : UIViewController <TableSection,MFMailComposeViewControllerDelegate> 
{
    SectionedTable *	    myTableView;
    
    File *		    myFile;
    FileType *		    myFileType;
    
    NSArray *		    myFixedUploadActions;
    NSMutableArray *	    myCustomUploadActions;
    NSArray *		    myFileSpecificActions;
    NSInteger		    myCustomUploadEditIndex;
    
    FileInfoCell *	    myFileInfoCell;
    ConnectForOptionsCell * myConnectForInfoCell;
    
    BCConnection *	    myConnection;
    BOOL		    myIsBriefcaseConnection;
    
    NSCountedSet *	    myInProgressIdentifiers;
}

@property (retain,nonatomic) File * file;

- (void)launchAction:(FileAction*)action;

@end
