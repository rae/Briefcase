//
//  ImageTile.m
//  Briefcase
//
//  Created by Michael Taylor on 25/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ImageTileView.h"


@implementation ImageTileView

@synthesize displayed = myDidDisplay;
@synthesize delegate = myDelegate;

- (id)initWithFrame:(CGRect)frame image:(CGImageRef)image subRegion:(CGRect)region
{
    if (self = [super initWithFrame:frame]) 
    {
	myDidDisplay = NO;
	[self _extractRect:region fromImage:image];
    }
    return self;
}

- (void)_extractRect:(CGRect)rect fromImage:(CGImageRef)image
{
    UIGraphicsBeginImageContext(self.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Flip the image
    CGContextTranslateCTM(context, 0.0, self.frame.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGImageRef sub_image = CGImageCreateWithImageInRect(image, rect);
    if (sub_image)
    {
	CGContextDrawImage(context, self.bounds, sub_image);
	CGImageRelease(sub_image);
    }
    
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    myDidDisplay = YES;
    if (myDelegate)
	[myDelegate imageTileDidDisplay:self];
}

- (void)dealloc 
{
    [super dealloc];
}

@end
