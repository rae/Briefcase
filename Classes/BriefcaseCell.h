//
//  BriefcaseCell.h
//  Briefcase
//
//  Created by Michael Taylor on 17/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GradientCell.h"

#define kBriefcaseCellId	@"Briefcase Cell"
#define kBriefcaseCellHeight	64.0

@class File;

enum BriefcaseCellAccessory {
    kInfoIcon,
    kUploadIcon
};

@interface BriefcaseCell : GradientCell 
{
    UIImageView *	myIconView;
    UILabel *		myFileName;
    UILabel *		myFileType;
    
    File *		myFile;
}

@property (nonatomic,retain) UIImage *	icon;
@property (nonatomic,retain) NSString * fileName;
@property (nonatomic,retain) NSString * fileType;
@property (nonatomic,retain) File *	file;

+ (void)setBriefcaseCellAccessory:(enum BriefcaseCellAccessory)accessory;


// Private
- (void)_updateButton;

@end
