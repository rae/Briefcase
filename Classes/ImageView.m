//
//  ImageView.m
//  Briefcase
//
//  Created by Michael Taylor on 23/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ImageView.h"
#import "ImageTileView.h"
#import "File.h"
#import "UpgradeAlert.h"

#define kMaxTileSize (1024 * 1024)
#define kOverlapSize 4

NSString * kImageViewImageDisplayed = @"Image View Displayed";

CGSize scaleSize(CGSize size, CGFloat scale)
{
    return CGSizeMake(size.width * scale, size.height * scale);
}

@implementation ImageView

- (id)init
{ 
    if (self = [super initWithFrame:CGRectZero]) 
    {
	myImage = NULL;
	myTileView = [[UIView alloc] initWithFrame:CGRectZero];
	[self addSubview:myTileView];
    }
    return self;
    
}

- (void)dealloc 
{    
    for (UIView * view in myTileView.subviews)
	[view removeFromSuperview];

    CGImageRelease(myImage);
    [myPendingTiles release];
    [super dealloc];
}

- (void)displayTiles
{
    if (myPendingTiles) 
    {
	for (UIView * tile in myPendingTiles)
	{
	    [myTileView addSubview:tile];
	}
	[myPendingTiles release];
	myPendingTiles = nil;
    }	
}

#pragma mark Properties

@synthesize maxScale = myMaxScale;

- (CGSize)imageSize
{
    return CGSizeMake(CGImageGetWidth(myImage), CGImageGetHeight(myImage));
}

- (CGImageRef)image
{
    return myImage;
}

- (void)addImageTile:(CGRect)dest_rect fromSourceRect:(CGRect)source_rect
{
    ImageTileView * tile_view = nil;

    tile_view = [[ImageTileView alloc] initWithFrame:dest_rect 
					       image:myImage
					   subRegion:source_rect];
    tile_view.delegate = self;
    
    if (!myPendingTiles)
	myPendingTiles = [[NSMutableArray alloc] initWithCapacity:4];
    [myPendingTiles addObject:tile_view];
    [tile_view release];    
}

- (void)setImage:(CGImageRef)image
{
    int width, height;
    CGRect source_rect, dest_rect;
    float aspect_ratio;
    
    if (myImage)
	CGImageRelease(myImage);
    
    [myPendingTiles release];
    myPendingTiles = nil;
    
    // Remove previous tiled sub views
    for (UIView * view in myTileView.subviews)
	[view removeFromSuperview];
    
    myImage = image;
    if (image)
	CGImageRetain(image);
    else
    {
	return;
    }
    
    width = CGImageGetWidth(image);
    height = CGImageGetHeight(image);
    
    aspect_ratio = (float)width / (float)height;
    
    // Create new subview tiles
    if (height * width <= kMaxTileSize) 
    {
	source_rect = dest_rect = CGRectMake(0.0, 0.0, width, height);
	[self addImageTile:dest_rect fromSourceRect:source_rect];
	
	myTileView.frame = source_rect;
	
	// Display image right away
	[self displayTiles];
    }
    else
    {
	// 2x1 tiling
	int source_overlap;
	float scale_factor;
	
	if (aspect_ratio > 1.0)
	{
	    // split into two side-by-side tiles
	    scale_factor = (float)(2 * kMaxTileSize) / 
			   (width * height + kOverlapSize * height);
	    
	    if (scale_factor < 1.0)
		source_overlap = kOverlapSize / scale_factor;
	    else 
		source_overlap = kOverlapSize;
	    
	    source_rect.origin = CGPointZero;
	    source_rect.size.width = width / 2.0 + source_overlap;
	    source_rect.size.height = height;
	    
	    dest_rect.origin = CGPointZero;
	    
	    if (scale_factor < 1.0)
	    {
		dest_rect.size.width = floorf((scale_factor * width + kOverlapSize) / 2.0);
		dest_rect.size.height = floorf(scale_factor * height);
	    }
	    else
		dest_rect = source_rect;
	    
	    [self addImageTile:dest_rect fromSourceRect:source_rect];
	    
	    dest_rect.origin.x = dest_rect.size.width - (kOverlapSize / 2.0);
	    source_rect.origin.x = source_rect.size.width - (source_overlap / 2.0);
	    
	    [self addImageTile:dest_rect fromSourceRect:source_rect];
	    
	    myTileView.frame = CGRectMake(0.0, 0.0, 
					  dest_rect.size.width + dest_rect.origin.x, 
					  dest_rect.size.height);
	}
	else
	{
	    // split into two stacked tiles
	    scale_factor = (float)(2 * kMaxTileSize) / 
			   (width * height + kOverlapSize * width);
	    
	    if (scale_factor < 1.0)
		source_overlap = kOverlapSize / scale_factor;
	    else 
		source_overlap = kOverlapSize;
	    
	    source_rect.origin = CGPointZero;
	    source_rect.size.width = width;
	    source_rect.size.height = height / 2.0 + source_overlap;
	    
	    dest_rect.origin = CGPointZero;
	    
	    if (scale_factor < 1.0)
	    {
		dest_rect.size.width = floorf(scale_factor * width);
		dest_rect.size.height = floorf((scale_factor * height+ kOverlapSize) / 2.0);
	    }
	    else
		dest_rect = source_rect;
	    
	    [self addImageTile:dest_rect fromSourceRect:source_rect];
	    
	    dest_rect.origin.y = dest_rect.size.height - (kOverlapSize / 2.0);
	    source_rect.origin.y = source_rect.size.height - (source_overlap / 2.0);
	    
	    [self addImageTile:dest_rect fromSourceRect:source_rect];
	    
	    myTileView.frame = CGRectMake(0.0, 0.0, 
					  dest_rect.size.width, 
					  dest_rect.size.height + dest_rect.origin.y);
	}
    }
    
    // Set our bounds    
    myTileView.center = CGPointMake(self.bounds.size.width / 2.0, 
				    self.bounds.size.height / 2.0);
    
    // Scale the large tiled view down to our view's size
    float scale = self.bounds.size.width / (float)myTileView.frame.size.width;
    CGAffineTransform transform;
    transform = CGAffineTransformMakeScale(scale, scale);
    myMaxScale = 1.0 / scale;
    myTileView.transform = transform;    
    
    [self setNeedsDisplay];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

- (void)setTransform:(CGAffineTransform)transform
{
    [super setTransform:transform];
//    [self setNeedsDisplay];
}


- (void)imageTileDidDisplay:(ImageTileView*)view
{
    for (ImageTileView * tile in [myTileView subviews])
    {
	if (!tile.displayed)
	    return;
    }
    
    // Report that all tiles have been drawn
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kImageViewImageDisplayed object:self];
}
@end
