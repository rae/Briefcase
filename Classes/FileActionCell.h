//
//  FileActionCell.h
//  Briefcase
//
//  Created by Michael Taylor on 21/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FileActionCell : UITableViewCell {
    BOOL	myShowDisclosureAccessoryWhenEditing;
    UILabel *	myLabel;
}

@property (nonatomic,assign) BOOL showDisclosureAccessoryWhenEditing;
@property (nonatomic,assign) BOOL showSpinner;

@end
