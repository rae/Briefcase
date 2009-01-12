//
//  ConnectionBrowserController.h
//  Briefcase
//
//  Created by Michael Taylor on 02/11/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ConnectionController;

@interface ConnectionBrowserController : NSObject <UITableViewDelegate, UITableViewDataSource> 
{
    IBOutlet UITableView *	    myTableView;
    IBOutlet ConnectionController * myConnectionController;
    
    NSMutableArray *		    myServices;
    NSNetServiceBrowser *	    mySSHBrowser;
    NSNetServiceBrowser *	    myBriefcaseBrowser;
    
    NSMutableArray *		    myHostList;
    NSDictionary *		    myEditItem;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

@end
