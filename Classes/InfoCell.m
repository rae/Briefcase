//
//  InfoCell.m
//  Briefcase
//
//  Created by Michael Taylor on 21/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "InfoCell.h"

#define kInfoCellLeftOffset	     8.0
#define kInfoCellTopOffset	    12.0
#define kInfoCellHeight		    20.0
#define kInfoLabelDefaultWidth	    50.0
#define kInfoSpacing		     5.0

@implementation InfoCell

@dynamic label;
@dynamic description;
@dynamic labelWidth;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
	myLabel = [[UILabel alloc] initWithFrame:frame];
	
	myLabel.textAlignment = UITextAlignmentRight;
	myLabel.backgroundColor = [UIColor clearColor];
	myLabel.opaque = NO;
	myLabel.textColor = [UIColor colorWithRed:0.347 green:0.416 blue:0.58 alpha:1.0];
	myLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
	
	[self.contentView addSubview:myLabel];
	
	myDescription = [[UILabel alloc] initWithFrame:frame];
	
	myDescription.backgroundColor = [UIColor clearColor];
	myDescription.opaque = NO;
	myDescription.textColor = [UIColor darkTextColor];
	myDescription.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
	
	[self.contentView addSubview:myDescription];
	
	myLabelWidth = kInfoLabelDefaultWidth;
    }
    return self;
}


//- (void)drawRect:(CGRect)rect {
//	// Drawing code
//	
//}

- (void)layoutSubviews
{	
    [super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
    
    CGRect label_frame = CGRectMake(contentRect.origin.x + kInfoCellLeftOffset, 
				    kInfoCellTopOffset, 
				    myLabelWidth, 
				    kInfoCellHeight);
    myLabel.frame = label_frame;
    
    CGFloat left = contentRect.origin.x + kInfoCellLeftOffset 
		   + myLabelWidth + kInfoSpacing;
    CGRect description_frame = CGRectMake(left, 
					  kInfoCellTopOffset, 
					  contentRect.size.width - left, 
					  kInfoCellHeight);
    myDescription.frame = description_frame;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	// Configure the view for the selected state
}


- (void)prepareForReuse {
    myLabelWidth = kInfoLabelDefaultWidth;
}


- (void)dealloc {
	[super dealloc];
}

#pragma mark Dynamic Properties

- (NSString*)label
{
    return myLabel.text;
}

- (void)setLabel:(NSString*)text
{
    myLabel.text = text;
}

- (NSString*)description
{
    return myDescription.text;
}

- (void)setDescription:(NSString*)text
{
    myDescription.text = text;
}

- (CGFloat)labelWidth
{
    return myLabelWidth;
}

- (void)setLabelWidth:(CGFloat)width
{
    myLabelWidth = width;
    [self layoutSubviews];
}

@end
