//
//  ScrolledImageView.m
//  navtest
//
//  Created by Michael Taylor on 14/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ScrolledImageView.h"
#import "Utilities.h"
#import "ImageView.h"

static const CGFloat kMaximumImageScale = 4.0;
static const NSTimeInterval kDoubleTapInterval = 0.25;

@implementation ScrolledImageView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{   
    if (myImageView)
    {
	[myImageView removeFromSuperview];
	[myImageView release];
	myImageView = nil;
    }
    
    if (newSuperview)
    {
	[myImageView release];
	myImageView = [[ImageView alloc] init];
	[self addSubview:myImageView];
    }
    
    self.backgroundColor = [UIColor blackColor];
    
    self.scrollEnabled = YES;
    self.multipleTouchEnabled = YES;
    self.bounces = YES;
    
    self.delegate = self;
}

- (void)dealloc 
{
    if (myImageView)
    {
	[myImageView removeFromSuperview];
	[myImageView release];
	myImageView = nil;
    }
    [super dealloc];
}

- (void)adjustFrameWithBounce:(BOOL)allowBounce
{
    static BOOL adjusting_frame = NO;
    
    if (adjusting_frame) return;
    
    adjusting_frame = YES;
    
    CGRect scroll_view_frame = self.bounds;
    CGRect image_view_frame = CGRectApplyAffineTransform(myImageView.bounds, myImageView.transform);
    
    CGPoint offset = self.contentOffset;
    
    // Center the image in dimensions where it is smaller than the view.
    // and make sure that the view is within the bounds of the image otherwise
    //
    if (image_view_frame.size.height <= scroll_view_frame.size.height)
	// Center the image in y
	offset.y = -(scroll_view_frame.size.height - image_view_frame.size.height) / 2.0;
    else if (!allowBounce)
    {
	if (offset.y + scroll_view_frame.size.height > image_view_frame.size.height)
	    offset.y = image_view_frame.size.height - scroll_view_frame.size.height;
	else if (offset.y < 0.0)
	    offset.y = 0.0;
    }
    
    if (image_view_frame.size.width <= scroll_view_frame.size.width)
	// Center the image in x
	offset.x = -(scroll_view_frame.size.width - image_view_frame.size.width) / 2.0;
    else if (!allowBounce)
    {
	if (offset.x + scroll_view_frame.size.width > image_view_frame.size.width)
	    offset.x = image_view_frame.size.width - scroll_view_frame.size.width;
	else if (offset.x < 0.0)
	    offset.x = 0.0;
    }
    
    
    self.contentOffset = offset;  
    
    adjusting_frame = NO;
}

- (void)resetScale
{
    [UIView beginAnimations:@"Reset Scale" context:nil];
    
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(resetScaleDone:finshed:context:)];
    
    
    CGRect image_view_frame = CGRectApplyAffineTransform(myImageView.bounds, myImageView.transform);

    CGPoint offset = self.contentOffset;
    CGPoint image_center = CGPointMake((image_view_frame.size.width / 2.0) - offset.x, 
				       (image_view_frame.size.height / 2.0) - offset.y);
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(self.center.x - image_center.x, 
								   self.center.y - image_center.y);
    
    myImageView.transform = transform;
    
    [UIView commitAnimations];
}

- (void)resetScaleDone:(NSString*)animation_id finshed:(BOOL)finished context:(void*)context
{
    // This will reset the image view's scale
    [self setImage:self.image];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    if (myEventDelegate && touch.tapCount > 1)
    {
        // Cancel previous calls
        [NSObject cancelPreviousPerformRequestsWithTarget:myEventDelegate];
    }
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    if (myEventDelegate && touch.tapCount == 1)
    {
        // Start to call the single tap method
        [(NSObject*)myEventDelegate performSelector:@selector(didSingleTap) 
                                         withObject:nil 
                                         afterDelay:kDoubleTapInterval]; 
    }   
    
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (myEventDelegate)
        // Cancel previous calls
        [NSObject cancelPreviousPerformRequestsWithTarget:myEventDelegate];
    
    [super touchesCancelled:touches withEvent:event];
}

#if 0
if (touch.phase == UITouchPhaseEnded && touch.tapCount == 1)
// Start to call the single tap method
[(NSObject*)myDelegate performSelector:@selector(didSingleTap) 
                            withObject:nil 
                            afterDelay:kDoubleTapInterval];
else if (touch.phase == UITouchPhaseBegan && touch.tapCount > 1)
// Cancel previous calls
[NSObject cancelPreviousPerformRequestsWithTarget:myDelegate];
else if (touch.phase == UITouchPhaseMoved)
[(NSObject*)myDelegate performSelector:@selector(didTouchMove) 
                            withObject:nil 
                            afterDelay:kDoubleTapInterval];
#endif

#pragma mark Scroll View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (myEventDelegate)
    {
        [(NSObject*)myEventDelegate performSelector:@selector(didTouchMove) 
                                         withObject:nil 
                                         afterDelay:kDoubleTapInterval];
    }   
    
    [self adjustFrameWithBounce:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView

{
    [self adjustFrameWithBounce:YES];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    [self adjustFrameWithBounce:YES];
    return myImageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [self adjustFrameWithBounce:YES];
}

- (void)viewBecameVisible
{
    [myImageView displayTiles];
}

#pragma mark Properties

@synthesize eventDelegate = myEventDelegate;

- (CGImageRef)image
{
    return myImageView.image;
}

- (void)setImage:(CGImageRef)image
{
    double image_scale_factor;
    UIScrollView * scroll_view = (UIScrollView*)self;
    
    CGRect image_view_frame = CGRectZero;
        
    CGSize image_size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    
    image_scale_factor = scaleFactorForRectWithinRect(scroll_view.frame.size, 
						      image_size);
    
    image_view_frame.size.height = (CGFloat)floor((double)image_size.height * image_scale_factor);
    image_view_frame.size.width = (CGFloat)floor((double)image_size.width * image_scale_factor);
        
    scroll_view.contentSize = image_view_frame.size;
    myImageView.frame = image_view_frame;   
    
    myImageView.image = image;
    
    if (myImageView.maxScale > kMaximumImageScale)
	scroll_view.maximumZoomScale = myImageView.maxScale;
    else
	scroll_view.maximumZoomScale = kMaximumImageScale;
    
    [self adjustFrameWithBounce:NO];
    
    myOriginalViewFrame = image_view_frame;
    myOriginalViewFrame.origin = self.contentOffset;
}

- (CGSize)imageSize
{
    return myImageView.imageSize;
}

@end
