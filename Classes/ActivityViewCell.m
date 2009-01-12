//
//  ActivityViewCell.m
//  Briefcase
//
//  Created by Michael Taylor on 07/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ActivityViewCell.h"
#import "NetworkOperation.h"

#define kActivityCellMargin	    8.0
#define kActivityCellInnerPadding   10.0
#define kActivityCellFontSize	    14.0
#define kActivityCellMinFontSize    12.0
#define kActivityCellProgressHeight 10.0

static UIImage * theCancelButton = nil;

@implementation ActivityViewCell

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier 
{    
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
    {
	myFont = [[UIFont systemFontOfSize:kActivityCellFontSize] retain];
	myBoldFont = [[UIFont boldSystemFontOfSize:kActivityCellFontSize] retain];
	myProgressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
	
	[self.contentView addSubview:myProgressView];
	
	if (!theCancelButton)
	{
	    theCancelButton = [UIImage imageNamed:@"cancel.png"];
	    [theCancelButton retain];
	}
	
	NSAssert(theCancelButton,@"Null image!");
	
	UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:theCancelButton forState:UIControlStateNormal];
	[button sizeToFit];
	[button addTarget:self action:@selector(cancelJob) 
	 forControlEvents:UIControlEventTouchUpInside];
	
	self.accessoryView = button;
    }
    return self;
}

- (void)dealloc 
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
    
    [myOperation release];
    
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect content_rect = [self.contentView bounds];
    
    CGSize title_size = [myOperation.title sizeWithFont:myBoldFont];
    CGFloat description_width = content_rect.size.width - title_size.width - 
				2 * kActivityCellMargin - 
				kActivityCellInnerPadding;
    
    // Draw label
    CGContextSetRGBFillColor(context, 0.347, 0.416, 0.58, 1.0);
    CGPoint location = CGPointMake(kActivityCellMargin, kActivityCellMargin);
    [myOperation.title drawAtPoint:location withFont:myBoldFont];
    
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
    location.x += title_size.width + kActivityCellInnerPadding;
    [myOperation.description drawAtPoint:location 
			 forWidth:description_width 
			 withFont:myFont 
		      minFontSize:kActivityCellMinFontSize
		   actualFontSize:nil
		    lineBreakMode:UILineBreakModeMiddleTruncation 
	       baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect content_rect = [self.contentView bounds];
    
    CGRect frame = CGRectMake(kActivityCellMargin, content_rect.size.height 
			      - kActivityCellProgressHeight - kActivityCellMargin, 
			      content_rect.size.width - 2 * kActivityCellMargin, 
			      kActivityCellProgressHeight);
    myProgressView.frame = frame;
}

#pragma mark Job Cancelation

- (void)cancelJob
{
    [myOperation cancel];
}

- (void)updateProgress:(NSNotification*)notification
{
    myProgressView.progress = myOperation.progress;
}
    
#pragma mark Properties

@synthesize operation = myOperation;

- (float)progress
{
    return myProgressView.progress;
}

- (void)setProgress:(float)progress
{
    myProgressView.progress = progress;
}

- (void)setOperation:(NetworkOperation*)op
{
    [myOperation release];
    
    myOperation = [op retain];
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    
    // Cancel any previous registrations
    [center removeObserver:self];
    
    // Watch the progress of the operation
    [center addObserver:self 
	       selector:@selector(updateProgress:) 
		   name:kNetworkOperationProgress
		 object:op];
    
    // Set up our initial progress
    self.progress = op.progress;
    
    [self setNeedsDisplay];
}

@end
