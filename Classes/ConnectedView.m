//
//  ConnectedView.m
//  Briefcase
//
//  Created by Michael Taylor on 27/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ConnectedView.h"
#import "ConnectionController.h"

// Image Coordinates
#define kBriefcaseLogoInitialOffsetX	-62.0
#define kBriefcaseLogoInitialOffsetY	  0.0
#define kBriefcaseLogoCenteredOffsetX	 15.0

#define kBriefcaseTextInitialOffsetX	 40.0
#define kBriefcaseTextInitialOffsetY	-14.0

#define kGradientCenterOffsetY		-20.0

#define kBinaryTextOffsetY		-10.0

#define kHostnameMaxWidth		200.0
#define kHostnameDefaultFontSize	 20.0
#define kHostnameMinFontSize		 11.0
#define kHostnameOffsetY		 46.0

#define kInternalPadding		 10.0

// Animations
#define kBriefcaseMoveAnimationSeconds	  0.5
#define kBinaryTextAnimationLoopSeconds	 10.0

@implementation ConnectedView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) 
    {
	
	// Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Make sure our subviews don't show outside our bounds
    self.clipsToBounds = YES;
    
    // View for binary text
    UIImage * image = [UIImage imageNamed:@"binary_text.png"];
    myBinaryTextView = [[UIImageView alloc] initWithImage:image];
    myBinaryTextView.opaque = YES;
    [self addSubview:myBinaryTextView];
    
    // Briefcase image from logo
    image = [UIImage imageNamed:@"briefcase.png"];
    myBriefcaseLogoView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:myBriefcaseLogoView];
    
    // Briefcase text from logo
    image = [UIImage imageNamed:@"briefcase_text.png"];
    myBriefcaseTextView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:myBriefcaseTextView];
    
    // Set up font
    myHostNameFont = [UIFont systemFontOfSize:kHostnameDefaultFontSize];
    
    myDisconnectView.hidden = NO;
    
    myIsInitialized = NO;
    
    
    [super awakeFromNib];
}

- (void)didMoveToSuperview
{
    CGPoint center = self.center;
    center.y += kGradientCenterOffsetY;
    self.gradientCenter = center;
    
    if (!myIsInitialized)
    {
	[self resetViewAnimated:NO];
	myIsInitialized = YES;
    }
}

- (void)resetViewAnimated:(BOOL)animated
{
    [UIView beginAnimations:nil context:NULL];
    
    // Briefcase logo
    CGPoint center;
    center = CGPointMake(myGradientCenter.x + kBriefcaseLogoInitialOffsetX, 
			 myGradientCenter.y + kBriefcaseLogoInitialOffsetY);
    myBriefcaseLogoView.center = center;
    
    // Briefcase text
    center = CGPointMake(myGradientCenter.x + kBriefcaseTextInitialOffsetX, 
			 myGradientCenter.y + kBriefcaseTextInitialOffsetY);
    myBriefcaseTextView.center = center;
    
    // Binary text
    center = CGPointMake(-myBinaryTextView.frame.size.width / 2.0,
			 myGradientCenter.y + kBinaryTextOffsetY);
    
    [UIView commitAnimations];
    
    myBinaryTextView.center = center;
    myBinaryTextView.hidden = YES;
    
    [myDisconnectView removeFromSuperview];
    [self addSubview:myConnectingView];
}

- (void)setConnected:(BOOL)connected
{
    if (connected)
    {
	myBinaryTextView.hidden = NO;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:kBriefcaseMoveAnimationSeconds];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(startBinaryTextAnimation:finished:context:)];
	
	// Move the briefcase to the center of the gradient
	myBriefcaseLogoView.center = CGPointMake(myGradientCenter.x + kBriefcaseLogoCenteredOffsetX, 
						 myGradientCenter.y);
	
	// Move the logo text off of the screen
	CGFloat x;
	x = (myBriefcaseTextView.frame.size.width / 2.0) + 
	self.frame.origin.x + self.frame.size.width;
	myBriefcaseTextView.center = CGPointMake(x, myBriefcaseTextView.center.y);
	
	// Bring the binary text onto the screen
	myBinaryTextView.center = CGPointMake(0.0, myGradientCenter.y + kBinaryTextOffsetY);
	
	[myConnectingView removeFromSuperview];
	[self addSubview:myDisconnectView];
	
	[UIView commitAnimations];
    }
    else
	[self resetViewAnimated:YES];
}

- (void)startBinaryTextAnimation:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:kBinaryTextAnimationLoopSeconds];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationRepeatCount:10000.0];
    
    myBinaryTextView.center = CGPointMake(self.frame.size.width, 
					  myGradientCenter.y + kBinaryTextOffsetY);
    
    [UIView commitAnimations];
}

- (void)dealloc {
    CGGradientRelease(myGradient);
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect content_rect = self.bounds;
    
    // Determine the width and position of the hostname when drawn
    CGFloat actual_size;
    CGSize size = [myHostName sizeWithFont:myHostNameFont 
			       minFontSize:kHostnameMinFontSize 
			    actualFontSize:&actual_size
				  forWidth:kHostnameMaxWidth
			     lineBreakMode:UILineBreakModeMiddleTruncation];
    
    myHostNameLocation.y = kHostnameOffsetY;
    myHostNameLocation.x = content_rect.origin.x + 
			   ((content_rect.size.width - size.width) / 2);
    
    // Move the disclosure button and icon to be snug to the hostname
    CGRect frame = myDisclosureButton.frame;
    frame.origin.x = myHostNameLocation.x + size.width + kInternalPadding;
    myDisclosureButton.frame = frame;
    
    // Move the icon image as well
    frame = myHostIconImageView.frame;
    frame.origin.x = myHostNameLocation.x - frame.size.width - kInternalPadding;
    myHostIconImageView.frame = frame;
}

- (void)drawRect:(CGRect)rect 
{
    [super drawRect:rect];
    
    CGFloat actual_size;
    [myHostName drawAtPoint:myHostNameLocation 
		   forWidth:kHostnameMaxWidth 
		   withFont:myHostNameFont 
		minFontSize:kHostnameMinFontSize  
	     actualFontSize:&actual_size
	      lineBreakMode:UILineBreakModeMiddleTruncation
	 baselineAdjustment:UIBaselineAdjustmentAlignCenters];
    
}

#pragma mark Properties

- (NSString*)hostName
{
    return myHostName;
}

- (void)setHostName:(NSString*)name
{
    myHostName = [name retain];
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (UIImage*)hostIcon
{
    return myHostIconImageView.image;
}

- (void)setHostIcon:(UIImage*)image
{
    myHostIconImageView.image = image;
}

@end
