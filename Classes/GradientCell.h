//
//  GradientCell.h
//  Briefcase
//
//  Created by Michael Taylor on 07/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GradientCell : UITableViewCell 
{
    UILabel * myLabel;
}

- (void)_createGradient;

@end
