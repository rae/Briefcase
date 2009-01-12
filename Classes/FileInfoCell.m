//
//  FileInfoCell.m
//  Briefcase
//
//  Created by Michael Taylor on 23/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "FileInfoCell.h"
#import "Utilities.h"

#define kFileInfoCellDefaultIconSize 64.0
#define kFileInfoCellVerticalMargin   8.0
#define kFileInfoCellHorizontalMargin 5.0
#define kFileInfoCellAttributeHeight 16.0
#define kFileInfoCellPadding	      5.0
#define kFileInfoCellIconMaxWidth    64.0
#define kFileInfoCellLabelWidth	     60.0
#define kFileInfoCellMinHeight       (kFileInfoCellVerticalMargin * 2.0 + \
				      kFileInfoCellDefaultIconSize + 2.0)
#define kFileInfoCellMinFontSize     10.0
#define kFileInfoCellBaseCellHeight  (kFileInfoCellVerticalMargin * 2.0)

@implementation FileInfoCell

@dynamic icon;
@dynamic attributes;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier 
{
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
    {
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
	myLabelFont = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
	myValueFont = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	
	myLabelColor = [[UIColor alloc] initWithRed:0.347 green:0.416 blue:0.58 alpha:1.0];
	myValueColor = [[UIColor blackColor] retain];
	
	myImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	[self.contentView addSubview:myImageView];
    }
    return self;
}

- (void)dealloc 
{
    [myLabelFont release];
    [myValueFont release];
    [myLabelColor release];
    [myValueColor release];
    [myAttributes release];
    [super dealloc];
}

- (void)layoutSubviews
{
    NSArray * attribute_pair;
    
    [super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
    
    CGRect icon_rect, label_rect, value_rect, frame;
    icon_rect.origin = CGPointMake(kFileInfoCellHorizontalMargin, 
				   kFileInfoCellVerticalMargin);
    
    // How wide would the labels like to be
    label_rect = CGRectZero;
    value_rect = CGRectZero;
    for (attribute_pair in myAttributes) 
    {
	NSString * title = [attribute_pair objectAtIndex:0];
	NSString * value = [[attribute_pair objectAtIndex:1] description];
	
	CGSize title_size, value_size;
	title_size = [title sizeWithFont:myLabelFont];
	value_size = [value sizeWithFont:myValueFont];
	
	if (value_size.width > value_rect.size.width)
	    value_rect.size = value_size;
	if (title_size.width > label_rect.size.width)
	    label_rect.size = title_size;
    }
    
    // Caculate maximum icon size
    CGSize max_size;
    CGFloat preferred_width = contentRect.size.width - value_rect.size.width - 
			      label_rect.size.width - kFileInfoCellPadding - 
			      (2.0 * kFileInfoCellHorizontalMargin); 
    max_size.width = MAX(preferred_width, kFileInfoCellDefaultIconSize);
    max_size.height = self.preferredHeight - (2.0 * kFileInfoCellVerticalMargin);
    
    double scale_factor = scaleFactorForRectWithinRect(max_size, self.icon.size);
    icon_rect.size.width = (CGFloat)((double)self.icon.size.width * scale_factor);
    icon_rect.size.height = (CGFloat)((double)self.icon.size.height * scale_factor);
    myImageView.frame = icon_rect;
    
    label_rect.origin.x = kFileInfoCellHorizontalMargin + icon_rect.size.width + 
			  kFileInfoCellPadding;
    value_rect.origin.x = label_rect.origin.x + label_rect.size.width + 
			  kFileInfoCellPadding;
    value_rect.size.width = contentRect.size.width - value_rect.origin.x - 
			    kFileInfoCellHorizontalMargin;
    
    // Find our existing labels
    NSMutableArray * labels = [NSMutableArray arrayWithCapacity:[myAttributes count] * 2];
    for (id child in self.contentView.subviews)
	if ([child isMemberOfClass:[UILabel class]])
	    [labels addObject:child];
    
    // Make sure we've got the right number of labels
    NSInteger difference = [myAttributes count] * 2 - [labels count];
    if (difference < 0)
	// Remove some items
	for (NSInteger count = 0; count > difference; count--) 
	{
	    [[labels lastObject] removeFromSuperview];
	    [labels removeLastObject];
	}
    else if (difference > 0)
	// Need some new labels
	for (NSInteger count = 0; count < difference; count++) 
	{
	    UILabel * new_label = [[UILabel alloc] initWithFrame:CGRectZero];
	    [self.contentView addSubview:new_label];
	    [labels addObject:new_label];
	}
    
    // layout the labels
    CGFloat y_offset = kFileInfoCellVerticalMargin;
    for (attribute_pair in myAttributes) 
    {
	NSString * title = [attribute_pair objectAtIndex:0];
	NSString * value = [[attribute_pair objectAtIndex:1] description];
	
	UILabel * label_label = [labels lastObject];
	[labels removeLastObject];
	
	UILabel * value_label = [labels lastObject];
	[labels removeLastObject];
	
	frame = label_rect;
	frame.origin.y = y_offset;
	label_label.text = title;
	label_label.font = myLabelFont;
	label_label.frame = frame;
	label_label.textColor = myLabelColor;
	label_label.opaque = YES;
	label_label.textAlignment = UITextAlignmentRight;
	label_label.lineBreakMode = UILineBreakModeClip;
	label_label.adjustsFontSizeToFitWidth = NO;
	
	frame = value_rect;
	frame.origin.y = y_offset;
	value_label.text = value;
	value_label.font = myValueFont;
	value_label.frame = frame;
	value_label.textColor = myValueColor;
	value_label.opaque = YES;
	value_label.textAlignment = UITextAlignmentLeft;
	value_label.lineBreakMode = UILineBreakModeMiddleTruncation;
	value_label.adjustsFontSizeToFitWidth = YES;
	value_label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	value_label.minimumFontSize = kFileInfoCellMinFontSize;
	
	y_offset += kFileInfoCellAttributeHeight;
    }    
}

- (UIImage*)icon
{
    return myImageView.image;
}

- (void)setIcon:(UIImage*)image
{
    myImageView.image = image;
    [self setNeedsLayout];
}

- (NSArray*)attributes
{
    return myAttributes;
}

- (void)setAttributes:(NSArray*)attributes
{
    myAttributes = [attributes retain];
    [self setNeedsLayout];
}

- (NSInteger)preferredHeight
{
    CGFloat height = kFileInfoCellBaseCellHeight + 
    [myAttributes count] * kFileInfoCellAttributeHeight;
    return MAX(kFileInfoCellMinHeight, height);
}

@end
