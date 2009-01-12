//
//  FreeSpaceView.m
//  Briefcase
//
//  Created by Michael Taylor on 01/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "FreeSpaceView.h"
#import "FreeSpaceController.h"
#import "Utilities.h"
#import "File.h"

static CGFloat  kHorizontalMargin   = 4.0;
static CGFloat  kSpacing	    = 3.0;
static float	kFontSize	    = 10.0;

static UIColor * theHighlightColor  = nil;
static UIColor * theBackgroundColor = nil;
static UIColor * theTextColor	    = nil;
static UIFont *  theLabelFont	    = nil;
static UIFont *  theValueFont	    = nil;

@implementation FreeSpaceView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}


- (void)awakeFromNib
{
    if (!theHighlightColor)
    {
	theHighlightColor = [[UIColor grayColor] retain];
	theBackgroundColor = [[UIColor alloc] initWithWhite:0.059 alpha:1.0];
	theTextColor = [[UIColor whiteColor] retain];
	theLabelFont = [[UIFont systemFontOfSize:kFontSize] retain];
	theValueFont = [[UIFont systemFontOfSize:kFontSize] retain];
    }
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self 
	       selector:@selector(_freeSpaceChanged:) 
		   name:kFreeSpaceChanged 
		 object:nil];
    
    [center addObserver:self 
	       selector:@selector(_freeSpaceChanged:) 
		   name:kFileDeleted 
		 object:nil];
    
    [center addObserver:self 
	       selector:@selector(_freeSpaceChanged:) 
		   name:kDirectoryDeleted 
		 object:nil];
    
    myRefreshPending = NO;
}

- (void)dealloc 
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
    
    [super dealloc];
}

- (void)drawRect:(CGRect)rect 
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [theBackgroundColor CGColor]);
    CGContextFillRect(context, rect);
    
    // Draw the highlight line
    CGContextSetStrokeColorWithColor(context, [theHighlightColor CGColor]);
    CGContextSetLineWidth(context, 1.0);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.origin.x, 
			 rect.origin.y + 0.5);
    CGContextAddLineToPoint(context, 
			    rect.origin.x + rect.size.width,
			    rect.origin.y + 0.5);
    CGContextStrokePath(context);
    
    // Draw the text
    FreeSpaceController * free_controller = [FreeSpaceController sharedController];
    NSString * free_label = NSLocalizedString(@"Free Space:",@"Label for UI element that shows the amount of free space left on the device");
    NSString * free_value = [Utilities humanReadibleMemoryDescription:free_controller.freeSpace];
    
    NSString * used_label = NSLocalizedString(@"Used Space:",@"Label for UI element that shows the amount of space used by files in Briefcase");
    NSString * used_value = [Utilities humanReadibleMemoryDescription:free_controller.usedSpace];
    CGContextSetFillColorWithColor(context, [theTextColor CGColor]);

    CGSize size = [free_label sizeWithFont:theLabelFont];
    CGPoint location;
    location.x = kHorizontalMargin;
    location.y = (self.bounds.size.height - size.height) / 2.0;
    
    [free_label drawAtPoint:location withFont:theLabelFont];
    location.x += size.width + kSpacing;
    [free_value drawAtPoint:location withFont:theValueFont];
    
    size = [used_value sizeWithFont:theValueFont];
    location.x = self.bounds.size.width - size.width - kHorizontalMargin;
    [used_value drawAtPoint:location withFont:theValueFont];
    size = [used_label sizeWithFont:theLabelFont];
    location.x -= size.width + kSpacing;
    [used_label drawAtPoint:location withFont:theValueFont];
    
    [super drawRect:rect]; 
    
    myRefreshPending = NO;
}

- (void)_freeSpaceChanged:(NSNotification*)notification
{
    if (myRefreshPending) return;
    
    myRefreshPending = YES;
    [self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:1.0];
}

@end
