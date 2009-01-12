//
//  ActivityViewCell.h
//  Briefcase
//
//  Created by Michael Taylor on 07/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GradientCell.h"

@class NetworkOperation;

#define kActivityCellHeight 50.0

@interface ActivityViewCell : GradientCell 
{
    UIFont *		myFont;
    UIFont *		myBoldFont;
    UIProgressView *	myProgressView;
    
    NetworkOperation *	myOperation;
}

@property (retain) NetworkOperation * operation;

@end
