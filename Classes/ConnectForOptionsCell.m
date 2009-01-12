//
//  ConnectForOptionsCell.m
//  Briefcase
//
//  Created by Michael Taylor on 05/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ConnectForOptionsCell.h"

#define kConnectInfoVerticalPadding 4.0
#define kConnectInfoHorizontalPadding 20.0

@implementation ConnectForOptionsCell

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier 
{
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
    {
	myLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	[self.contentView addSubview:myLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    CGRect contentRect = [self.contentView bounds];
    
    contentRect.size = CGSizeMake(contentRect.size.width - 2.0 * kConnectInfoHorizontalPadding, 
				  contentRect.size.height - 2.0 * kConnectInfoVerticalPadding);
    contentRect.origin = CGPointMake(kConnectInfoHorizontalPadding, 
				     kConnectInfoVerticalPadding);	
    myLabel.frame = contentRect;
    
    myLabel.minimumFontSize = 10;
    myLabel.adjustsFontSizeToFitWidth = YES;
    myLabel.text = NSLocalizedString(@"Connection required for more options", 
				     @"Message for users viewing file information when not connected");
    myLabel.lineBreakMode = UILineBreakModeTailTruncation;
    myLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    
}


- (void)dealloc {
    [super dealloc];
}


@end
