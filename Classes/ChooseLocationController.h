//
//  ChooseLocationController.h
//  Briefcase
//
//  Created by Michael Taylor on 21/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SFTPSession;

@interface ChooseLocationController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    UITableView * myTableView;
    id		  myTarget;
    SEL		  myAction;
    SFTPSession * mySFTPSession;
    NSString *	  myRemotePath;
    NSArray *	  myDirectoryList;
}

@property (nonatomic,retain) NSString * remotePath;

+ (void)chooseLocationWithNavigationController:(UINavigationController*)parent 
					target:(id)target 
				      selector:(SEL)action;

- (id)initWithRemotePath:(NSString*)remote_path 
		  target:(id)target 
		selector:(SEL)action 
	     sftpSession:(SFTPSession*)session;

@end
