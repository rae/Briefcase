//
//  ActivityViewController.h
//  Briefcase
//
//  Created by Michael Taylor on 07/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivityViewController : UITableViewController 
{
    NSMutableArray *	myOperationList;
    BOOL		myAllowUpdates;
}

+ (UINavigationController*)navigationController;

@end
