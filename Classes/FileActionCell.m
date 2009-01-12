//
//  FileActionCell.m
//  Briefcase
//
//  Created by Michael Taylor on 21/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "FileActionCell.h"

const int kHorizontalMargin = 10.0;

@implementation FileActionCell

@synthesize showDisclosureAccessoryWhenEditing = myShowDisclosureAccessoryWhenEditing;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier 
{
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
    {
	myShowDisclosureAccessoryWhenEditing = NO;
	
	myLabel = [[UILabel alloc] initWithFrame:frame];
	myLabel.backgroundColor = [UIColor clearColor];
	myLabel.opaque = NO;
	myLabel.textColor = [UIColor blackColor];
	myLabel.highlightedTextColor = [UIColor blackColor];
	myLabel.font = [UIFont boldSystemFontOfSize:18];
	myLabel.adjustsFontSizeToFitWidth = YES;
	myLabel.textAlignment = UITextAlignmentCenter;
	myLabel.minimumFontSize = 10; 
	myLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	self.contentView.autoresizesSubviews = YES;
	[self.contentView addSubview:myLabel];
    }
    return self;
}

- (void)layoutSubviews
{	
    [super layoutSubviews];
    CGRect frame = [self.contentView bounds];
    frame.origin.x += kHorizontalMargin;
    frame.size.width -= 2.0 * kHorizontalMargin;
    
    myLabel.frame = frame;
}    

- (BOOL)showSpinner
{
    return self.accessoryView != nil;
}

- (void)setShowSpinner:(BOOL)show
{
    if (show)
    {
	UIActivityIndicatorView * spinner;
	spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[spinner sizeToFit];
	self.accessoryView = spinner;
	[spinner startAnimating];
	[spinner release];
    }
    else
	self.accessoryView = nil;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (myShowDisclosureAccessoryWhenEditing)
    {
	if (editing)
	{
	    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	    self.hidesAccessoryWhenEditing = NO;
	}
	else
	{
	    self.accessoryType = UITableViewCellAccessoryNone;
	}
    }
    [super setEditing:editing animated:animated];
}

#pragma mark Properties

- (NSString*)text
{
    return myLabel.text;
}

- (void)setText:(NSString*)text
{
    myLabel.text = text;
}

@end
