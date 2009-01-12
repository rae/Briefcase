//
//  GradientView.m
//  Briefcase
//
//  Created by Michael Taylor on 29/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "GradientView.h"

#define FLOATRGBA(A,B,C) (CGFloat)A/255.0,(CGFloat)B/255.0,(CGFloat)C/255.0,1.0

// View Gradient
#define kGradientCenterColor		FLOATRGBA(255, 255, 255)
#define kGradientEdgeColor		FLOATRGBA(111, 113, 133)

@implementation GradientView

@synthesize gradientCenter = myGradientCenter;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
	[self createGradient];
    }
    return self;
}

- (void)awakeFromNib
{
    [self createGradient];
}

- (void)createGradient
{
    if (myGradient) return;
    
    CGFloat color_components[] = {
	kGradientCenterColor,
	kGradientCenterColor,
	kGradientEdgeColor
    };
    CGFloat gradient_locations[] = {0.0, 0.05, 1.0};
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    myGradient = CGGradientCreateWithColorComponents(color_space, 
						     color_components,
						     gradient_locations, 
						     3);
    
    CGColorSpaceRelease(color_space);
}

- (void)drawRect:(CGRect)rect 
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat min_x = CGRectGetMinX(rect); 
    CGFloat min_y = CGRectGetMinY(rect); 
    CGFloat max_x = CGRectGetMaxX(rect); 
    CGFloat max_y = CGRectGetMaxY(rect); 
    CGFloat x, y;
    x = fabsf(min_x - myGradientCenter.x) > fabsf(max_x - myGradientCenter.x) ?
	min_x : max_x;
    y = fabsf(min_y - myGradientCenter.y) > fabsf(max_y - myGradientCenter.y) ?
	min_y : max_y;
    
    CGFloat radius = sqrtf(powf(x - myGradientCenter.x, 2.0) +
			   powf(y - myGradientCenter.y, 2.0));
    
    
    CGContextDrawRadialGradient(context, myGradient, myGradientCenter, 0.0, 
				myGradientCenter, radius, 0);
}


- (void)dealloc {
    [super dealloc];
}


@end
