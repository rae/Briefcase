//
//  DirectoryDownloadCell.m
//  Briefcase
//
//  Created by Michael Taylor on 19/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "DirectoryDownloadCell.h"

#define FLOATRGBA(A,B,C) (CGFloat)A/255.0,(CGFloat)B/255.0,(CGFloat)C/255.0,1.0

// View Gradient
#define kDirectoryCellBackgroundColor	FLOATRGBA(117, 120, 130)

@implementation DirectoryDownloadCell

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
	self.font = [UIFont boldSystemFontOfSize:16.0];
	self.textColor = [UIColor whiteColor];
	self.image = [UIImage imageNamed:@"download_directory.png"];
	self.text = NSLocalizedString(@"Download Directory", @"Button label for downloading a whole directory");
    }
    return self;
}

- (void)drawRect:(CGRect)rect 
{    
    if (!self.selected)
    {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Fill the background
	CGContextSetRGBFillColor(context, kDirectoryCellBackgroundColor);
	CGContextFillRect(context, rect);	
    }
    
    [super drawRect:rect]; 
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.contentView.opaque = NO;
    self.contentView.backgroundColor = [UIColor clearColor];
    
    for (UIView * subview in self.contentView.subviews)
    {
	subview.opaque = NO;
	subview.backgroundColor = [UIColor clearColor];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc 
{
    [super dealloc];
}


@end
