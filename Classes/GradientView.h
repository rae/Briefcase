//
//  GradientView.h
//  Briefcase
//
//  Created by Michael Taylor on 29/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GradientView : UIView {
    CGGradientRef   myGradient;
    CGPoint	    myGradientCenter;
}

@property (nonatomic,assign) CGPoint gradientCenter;

- (void)createGradient;

@end
