//
//  SystemInfoController.h
//  Briefcase
//
//  Created by Michael Taylor on 05/06/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SystemInfoController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *	    myTableView;
    BOOL		    myIsConnected;
}

-(id) init;

@end
