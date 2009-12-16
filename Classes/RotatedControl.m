//
//  VerticalSlider.m
//  Briefcase
//
//  Created by Michael Taylor on 09-12-07.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import "RotatedControl.h"


@implementation RotatedControl

- (void)updateControlTransform
{
    CGRect bounds = CGRectZero;
    bounds.size.height = self.bounds.size.width;
    bounds.size.width = self.bounds.size.height;
    myControl.bounds = bounds;
    myControl.transform = CGAffineTransformMake(0, 1, -1, 0, 
                                                floorf(bounds.size.height / 2.0), 
                                                floorf(bounds.size.width / 2.0));
}

- (void)dealloc {
    if (myControl)
        [myControl removeFromSuperview];
    [super dealloc];
}

- (void)layoutSubviews
{
    [self updateControlTransform];
}

#pragma mark Properties

@synthesize control = myControl;

- (void)setControl:(UIControl *)the_control
{
    if (myControl)
        [myControl removeFromSuperview];
    
    myControl = the_control;
    if (the_control) 
    {
        [self addSubview:the_control];
        the_control.center = CGPointZero;
        [self updateControlTransform];
        [self setNeedsLayout];
    }
}

@end
