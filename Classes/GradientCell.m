//
//  GradientCell.m
//  Briefcase
//
//  Created by Michael Taylor on 07/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "GradientCell.h"
#import "GradientView.h"

static CGGradientRef theCellGradient = NULL;

#define FLOATRGBA(A,B,C) (CGFloat)A/255.0,(CGFloat)B/255.0,(CGFloat)C/255.0,1.0
#define kCellGradientRightColor		FLOATRGBA(176, 178, 206)
#define kCellGradientLeftColor		FLOATRGBA(223, 223, 226)
#define kCellHighlight			FLOATRGBA(224, 224, 224)
#define kCellShadow			FLOATRGBA(184, 184, 184)

@implementation GradientCell

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
	[self _createGradient];
	myLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    return self;
}


- (void)_createGradient
{
    if (theCellGradient) return;
    
    CGFloat color_components[] = {
	kCellGradientLeftColor,
	kCellGradientRightColor
    };
    CGFloat gradient_locations[] = {0.0, 1.0};
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    theCellGradient = CGGradientCreateWithColorComponents(color_space, 
							  color_components,
							  gradient_locations, 
							  2);
    
    CGColorSpaceRelease(color_space);
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

- (void)drawRect:(CGRect)rect 
{    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Fill the background
    CGContextDrawLinearGradient(context, theCellGradient, rect.origin, 
				CGPointMake(rect.origin.x + rect.size.width, rect.origin.y), 
				0);
        
    // Draw the highlight line
    CGContextSetRGBStrokeColor(context, kCellHighlight);
    CGContextSetLineWidth(context, 1.0);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.origin.x, 
			 rect.origin.y + 0.5);
    CGContextAddLineToPoint(context, 
			    rect.origin.x + rect.size.width,
			    rect.origin.y + 0.5);
    CGContextStrokePath(context);
    
    // Draw the shadow line
    CGContextSetRGBStrokeColor(context, kCellShadow);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.origin.x, 
			 rect.origin.y + rect.size.height - 0.5);
    CGContextAddLineToPoint(context, 
			    rect.origin.x + rect.size.width,
			    rect.origin.y + rect.size.height - 0.5);
    CGContextStrokePath(context);
    
    [super drawRect:rect]; 
}


- (void)dealloc {
    [super dealloc];
}


@end
