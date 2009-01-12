//
//  InfoCell.h
//  Briefcase
//
//  Created by Michael Taylor on 21/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kInfoCellId @"Information Cell"

@interface InfoCell : UITableViewCell {
    UILabel * myLabel;
    UILabel * myDescription;
    CGFloat   myLabelWidth;
}

@property (assign,nonatomic) NSString * label;
@property (assign,nonatomic) NSString * description;
@property (assign,nonatomic) CGFloat    labelWidth;

@end
