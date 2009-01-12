//
//  BriefcaseCell.m
//  Briefcase
//
//  Created by Michael Taylor on 17/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BriefcaseCell.h"
#import "Utilities.h"
#import "UploadActionController.h"

#define kBriefcaseIconSize		57.0
#define kBriefcaseVerticalMargin	 3.0
#define kBriefcaseVerticalTextMargin    12.0
#define kBriefcaseHorizontalMargin	 5.0
#define kBriefcaseNameLabelHeight	24.0
#define kBriefcaseSizeLabelWidth	65.0
#define kBriefcaseInnerPadding		 4.0

#define kBriefcaseLargeTextSize		16.0
#define kBriefcaseSmallTextSize		12.0
#define kBriefcaseSmallTextMinSize	10.0

#define FLOATRGBA(A,B,C) (CGFloat)A/255.0,(CGFloat)B/255.0,(CGFloat)C/255.0,1.0

#define kInfoTextColor		FLOATRGBA( 95, 95, 97)
#define kTextHightlight		FLOATRGBA(255,255,255)

UIColor * UICOLOR(CGFloat r, CGFloat g, CGFloat b, CGFloat a)
{
    return [[UIColor alloc] initWithRed:r green:g blue:b alpha:a];
}

static NSMutableSet * theBriefcaseCells = nil;

static enum BriefcaseCellAccessory theBriefcaseCellAccessory = kInfoIcon;

@implementation BriefcaseCell

+ (void)setBriefcaseCellAccessory:(enum BriefcaseCellAccessory)accessory
{
    theBriefcaseCellAccessory = accessory;
}

- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame reuseIdentifier:kBriefcaseCellId])  
    {	
	myIconView = [[UIImageView alloc] init];
	myFileName = [[UILabel alloc] init];
	myFileType = [[UILabel alloc] init];
	
	// Set up the text shadows
	CGSize offset = CGSizeMake(0.0, 1.0);
	myFileName.shadowOffset = offset;
	myFileType.shadowOffset = offset;
		
	myFileName.font = [UIFont boldSystemFontOfSize:kBriefcaseLargeTextSize];
	
	UIFont * small_font = [UIFont boldSystemFontOfSize:kBriefcaseSmallTextSize];
	UIColor * info_color = UICOLOR(kInfoTextColor);
	
	// Set up the labels
	myFileName.backgroundColor = [UIColor clearColor];
	myFileName.highlightedTextColor = [UIColor whiteColor];
	
	myFileType.font = small_font;
	myFileType.textColor = info_color;
	myFileType.backgroundColor = [UIColor clearColor];
	myFileType.highlightedTextColor = [UIColor whiteColor];
	myFileType.adjustsFontSizeToFitWidth = YES;
	myFileType.minimumFontSize = kBriefcaseSmallTextMinSize;
		
	// Add the sub-views
	[self.contentView addSubview:myIconView];
	[self.contentView addSubview:myFileName];
	[self.contentView addSubview:myFileType];
	
	[self _updateButton];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews
{
    CGFloat horizontal_offset, vertical_offset;
    CGRect frame;
    
    [super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
    
    if (myIconView.image)
    {
	// Calculate frame for icon
	CGFloat width, height;
	CGSize size = myIconView.image.size;
	
	if (size.height <= kBriefcaseIconSize && size.width <= kBriefcaseIconSize)
	{
	    // Image already fits
	    width = size.width;
	    height = size.height;
	}
	else
	{
	    CGFloat aspect_ratio = size.width / size.height; 
	    
	    if (aspect_ratio > 1.0 )
	    {
		// We are bound by the width
		width = kBriefcaseIconSize;
		height = kBriefcaseIconSize / aspect_ratio;
	    }
	    else
	    {
		// We are bound by the height
		height = kBriefcaseIconSize;
		width = aspect_ratio * kBriefcaseIconSize;
	    }
	}
	horizontal_offset = contentRect.origin.x + kBriefcaseHorizontalMargin +
			    ((int)(kBriefcaseIconSize - width) / 2);
	vertical_offset = contentRect.origin.y + kBriefcaseVerticalMargin +
			  ((int)(kBriefcaseIconSize - height) / 2);
    
	frame = CGRectMake(horizontal_offset, vertical_offset, width, height);
	
	myIconView.frame = frame;
    }
    
    // Position file name
    horizontal_offset = contentRect.origin.x + 2 * kBriefcaseHorizontalMargin +
			kBriefcaseIconSize;
    vertical_offset = contentRect.origin.y + kBriefcaseVerticalTextMargin;
    
    frame = CGRectMake(horizontal_offset, vertical_offset,
		       contentRect.size.width - horizontal_offset - 
		       kBriefcaseHorizontalMargin,
		       kBriefcaseNameLabelHeight);
    myFileName.frame = frame;
    
    // Position file type
    vertical_offset += kBriefcaseNameLabelHeight;
    frame = CGRectMake(horizontal_offset, vertical_offset,
		       frame.size.width - kBriefcaseInnerPadding,
		       kBriefcaseNameLabelHeight);
    myFileType.frame = frame;
        
    // Turn on text shadows if we are not selected
    if (self.selected)
    {
	myFileName.shadowColor = nil;
	myFileType.shadowColor = nil;
    }
    else
    {
	UIColor * text_shadow = UICOLOR(kTextHightlight);
	myFileName.shadowColor = text_shadow;
	myFileType.shadowColor = text_shadow;
    }
    
    [super layoutSubviews];
}


- (void)_showFileInfo
{
    UploadActionController * upload_controller = [UploadActionController sharedController];
    [upload_controller fileForAction:myFile];
}

- (void)_updateButton
{
    if (myFile)
    {
	if (!self.accessoryView)
	{
	    UIButton * accessory_button = [[UIButton alloc] initWithFrame:CGRectZero];
	    self.accessoryView = accessory_button;
	    [accessory_button addTarget:self 
				 action:@selector(_showFileInfo) 
		       forControlEvents:UIControlEventTouchUpInside];
	}
	
	UIButton * accessory_button = (UIButton*)self.accessoryView;

	switch (theBriefcaseCellAccessory) 
	{
	    case kInfoIcon:
		[accessory_button setImage:[UIImage imageNamed:@"info_button.png"] 
				  forState:UIControlStateNormal];
		break;
	    case kUploadIcon:
		[accessory_button setImage:[UIImage imageNamed:@"upload_icon.png"] 
				  forState:UIControlStateNormal];
		break;
	    default:
		NSAssert(FALSE,@"Invalid state!");
		break;
	}
	[accessory_button sizeToFit];
    }
    else
    {
	// We are displaying a directory
	self.accessoryView = nil;
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

- (void)dealloc 
{
    [myFile release];
    [theBriefcaseCells removeObject:self];
    [super dealloc];
}

#pragma mark Properties

@dynamic icon;
@dynamic fileName;
@dynamic fileType;
@synthesize file = myFile;

- (UIImage*)icon
{
    return myIconView.image;
}

- (void)setIcon:(UIImage*)image
{
    myIconView.image = image;
}

- (NSString*)fileName
{
    return myFileName.text;
}

- (void)setFileName:(NSString*)name
{
    myFileName.text = name;
}

- (NSString*)fileType
{
    return myFileType.text;
}

- (void)setFileType:(NSString*)type
{
    myFileType.text = type;
}

- (void)setFile:(File*)file
{
    [myFile release];
    myFile = [file retain];
    [self _updateButton];
}

@end
