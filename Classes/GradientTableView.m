//
//  GradientTableView.m
//  Briefcase
//
//  Created by Michael Taylor on 08/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "GradientTableView.h"

static CGGradientRef theTableGradient = NULL;

#define FLOATRGBA(A,B,C) (CGFloat)A/255.0,(CGFloat)B/255.0,(CGFloat)C/255.0,1.0
#define kCellGradientRightColor		FLOATRGBA(153, 154, 178)
#define kCellGradientLeftColor		FLOATRGBA(188, 190, 219)

@implementation GradientTableView


- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style 
{
    if (self = [super initWithFrame:frame style:style]) 
    {
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    self.separatorColor = [UIColor colorWithWhite:0.72 alpha:1.0];
}

- (void)_createGradient
{
    if (theTableGradient) return;
    
    CGFloat color_components[] = {
	kCellGradientLeftColor,
	kCellGradientRightColor
    };
    CGFloat gradient_locations[] = {0.0, 1.0};
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    theTableGradient = CGGradientCreateWithColorComponents(color_space, 
							   color_components,
							   gradient_locations, 
							   2);
    
    CGColorSpaceRelease(color_space);
}

- (void)drawRect:(CGRect)rect 
{    
    if (!theTableGradient)
	[self _createGradient];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextDrawLinearGradient(context, theTableGradient, rect.origin, 
				CGPointMake(rect.origin.x + rect.size.width, rect.origin.y), 
				0);
    
    [super drawRect:rect];
}


- (void)dealloc 
{
    [super dealloc];
}


@end
