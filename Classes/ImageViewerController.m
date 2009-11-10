//
//  ImageViewerController.m
//  navtest
//
//  Created by Michael Taylor on 14/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ImageViewerController.h"
#import "ScrolledImageView.h"
#import "BriefcaseAppDelegate.h"
#import "Utilities.h"
#import "File.h"
#import "ImageView.h"

static const NSTimeInterval kHideUIInterval = 4.0;

@implementation ImageViewerController

@synthesize dualNavigationController = myDualNavController;

- (id)initWithFile:(File*)file
{
    if (self = [super initWithNibName:@"ImageViewer" bundle:nil]) 
    {
	myFile = [file retain];
	
	[mySpinner startAnimating];
	[self performSelectorInBackground:@selector(_loadImage:) withObject:myFile.path];
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(orientationDidChange:) 
		       name:UIDeviceOrientationDidChangeNotification
		     object:nil];
	
	[center addObserver:self 
		   selector:@selector(imageDidDisplay:) 
		       name:kImageViewImageDisplayed 
		     object:nil];
	
	// Set up the event monitor that helps us to know when
	// to hide the UI
//	myEventMonitor = [[EventMonitor alloc] init];
//	myEventMonitor.delegate = self;
//	myEventMonitor.idleEventDelay = kHideUIInterval;
	
	self.navigationItem.title = file.fileName;
    }
    return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
 - (void)loadView {
 }
 */

- (void)viewDidLoad 
{    
    UINavigationItem * item = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Files", @"Title for back button")];

    [myNavigationBar pushNavigationItem:item animated:NO];
    [myNavigationBar pushNavigationItem:self.navigationItem animated:NO];
    
    myImageViewOrientation = UIDeviceOrientationPortrait;
    
    myNavigationBar.delegate = self;
    
    myScrolledImageView.eventDelegate = self;
    
    @synchronized(self)
    {
	if (myStoredImage)
	{
	    myScrolledImageView.image = myStoredImage.CGImage;
	    [myStoredImage release];
	    
	    [mySpinner stopAnimating];
	    
	    if (!myScrolledImageView.image)
	    {
		// Setting the image failed, bail
		BriefcaseAppDelegate * delegate = [BriefcaseAppDelegate sharedAppDelegate];
		[delegate performSelector:@selector(popFullScreenView) 
			       withObject:nil 
			       afterDelay:0.5];
	    }
	}
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [myScrolledImageView viewBecameVisible];
//    myEventMonitor.viewToMonitor = self.view;
//    [myEventMonitor beginMonitoring];
}

- (void)viewDidDisappear:(BOOL)animated
{
//    [myEventMonitor endMonitoring];
}
 
- (void)orientationDidChange:(NSNotification*)notification
{
    static CGRect   current_bounds, new_bounds;
    static BOOL	    scale_up;
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if (orientation == UIDeviceOrientationUnknown   ||
	orientation == UIDeviceOrientationFaceUp    ||
	orientation == UIDeviceOrientationFaceDown  ||
	orientation == myImageViewOrientation) 
    {
	return;
    }
    
    // Determine if we need to scale up the view
    scale_up = UIDeviceOrientationIsPortrait(myImageViewOrientation) &&
	       UIDeviceOrientationIsLandscape(orientation);
    
    // Remember our new orientation
    myImageViewOrientation = orientation;
    
    current_bounds = self.view.bounds;
    
    CGAffineTransform rotation;
    switch (orientation) {
	case UIDeviceOrientationPortrait:
	    rotation = CGAffineTransformMake(1, 0, 0, 1, 0, 0);
	    new_bounds = CGRectMake(0, 0, current_bounds.size.width, current_bounds.size.height);
	    break;
	case UIDeviceOrientationPortraitUpsideDown:
	    rotation = CGAffineTransformMake(-1, 0, 0, -1, 0, 0);
	    new_bounds = CGRectMake(0, 0, current_bounds.size.width, current_bounds.size.height);
	    break;
	case UIDeviceOrientationLandscapeLeft:
	    rotation = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
	    new_bounds = CGRectMake(0, 0, current_bounds.size.height, current_bounds.size.width);
	    break;
	case UIDeviceOrientationLandscapeRight:
	    rotation = CGAffineTransformMake(0, -1, 1, 0, 0, 0);
	    new_bounds = CGRectMake(0, 0, current_bounds.size.height, current_bounds.size.width);
	    break;
	default:
	    // Ignore any other orientations
	    return;
    }
    
    if (scale_up)
    {
	CGSize landscape_size, portrait_size, image_size;
	double landscape_scale_to_fit, portrait_scale_to_fit;
	
	// Get the sizes of everything
	image_size = myScrolledImageView.imageSize;
	landscape_size = current_bounds.size;
	portrait_size = CGSizeMake(landscape_size.height, landscape_size.width);
	
	// Calculate the scales
	portrait_scale_to_fit = scaleFactorForRectWithinRect(portrait_size, image_size);
	landscape_scale_to_fit = scaleFactorForRectWithinRect(landscape_size, image_size);
	
	// Calculate the amount to scale up the image view
	CGFloat scale_factor = (CGFloat)(portrait_scale_to_fit / landscape_scale_to_fit);
	
	rotation = CGAffineTransformScale(rotation, scale_factor, scale_factor);
	
	new_bounds.size.height /= scale_factor;
	new_bounds.size.width /= scale_factor;
    }
    
        
    [UIView beginAnimations:@"Rotate Image" context:&new_bounds];
    
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(rotationFinished:finshed:context:)];
    
    myScrolledImageView.transform = rotation;
    
    [UIView commitAnimations];
}

- (void)rotationFinished:(NSString*)animation_id finshed:(BOOL)finished context:(void*)context
{
    CGRect old_bounds = myScrolledImageView.bounds;
    CGRect * bounds = (CGRect*)context;
    CGPoint offset = myScrolledImageView.contentOffset;
    
    myScrolledImageView.bounds = *bounds;
    
    // Move the offset so that the bounds stay centered in the same place
    CGFloat x_offset = (old_bounds.size.width - bounds->size.width) / 2.0;
    CGFloat y_offset = (old_bounds.size.height - bounds->size.height) / 2.0;
    offset.x += x_offset;
    offset.y += y_offset;
    
    myScrolledImageView.contentOffset = offset;
    [myScrolledImageView adjustFrameWithBounce:NO];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    myScrolledImageView.image = NULL;
    [[BriefcaseAppDelegate sharedAppDelegate] popFullScreenView];
    return NO;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [myFile release];
    [super dealloc];
}

- (IBAction)doImageAction
{
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil 
							delegate:self 
					       cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label")
					  destructiveButtonTitle:nil 
					       otherButtonTitles:NSLocalizedString(@"Add to Photo Album",@"Add a photo to the iPhone's photo album"),
			     nil];
    myIsDeleting = NO;
    [sheet showFromToolbar:myToolbar];
}

- (IBAction)deleteFile
{
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil 
							delegate:self 
					       cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label")
					  destructiveButtonTitle:NSLocalizedString(@"Delete Image",@"Delete an image from Briefcase") 
					       otherButtonTitles:nil
			     ];
    myIsDeleting = YES;
    [sheet showFromToolbar:myToolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (myIsDeleting)
    {
	if (buttonIndex == 0)
	{
	    [myFile delete];
	    [[BriefcaseAppDelegate sharedAppDelegate] popFullScreenView];
	}
	
    }
    else
    {
	if (buttonIndex == 0)
	{
	    [mySpinner startAnimating];
	    [self performSelector:@selector(addImageToPhotoAlbum)
		       withObject:nil 
		       afterDelay:0.0001];
	}
    }
}

- (void)addImageToPhotoAlbum
{
    UIImage * image = [[UIImage alloc] initWithContentsOfFile:myFile.path];
    UIImage * small_image = [[Utilities scaleImage:image toMaxSize:CGSizeMake(1024.0, 1024.0)] retain];
    
    UIImageWriteToSavedPhotosAlbum(small_image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    [small_image release];
    [image release];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error)
    {
	UIAlertView * server_alert;
	server_alert = [[UIAlertView alloc] initWithTitle:[error localizedDescription] 
						  message:[error localizedFailureReason]
						 delegate:self 
					cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button")
					otherButtonTitles:nil];
	
	[server_alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
	[server_alert release];
	
    }
    
    [mySpinner stopAnimating];
}

- (void)imageDidDisplay:(ImageView*)view
{
}


#pragma mark EventMonitor Delegate

- (void)didSingleTap
{
    self.controlsHidden = !self.controlsHidden;
}

- (void)didTouchMove
{
    if (!self.controlsHidden)
	self.controlsHidden = YES;
}

- (void)didIdle
{
    if (!self.controlsHidden)
	self.controlsHidden = YES;
}

#pragma mark Properties

- (BOOL)controlsHidden
{
    UIApplication * application = [UIApplication sharedApplication];
    return application.statusBarHidden;
}

- (void)setControlsHidden:(BOOL)hidden
{
    CGFloat alpha = 1;
    if (hidden)
	alpha = 0;
    
    [[UIApplication sharedApplication] setStatusBarHidden:hidden animated:YES];
    
    [UIView beginAnimations:@"Hide Image View Controls" context:NULL];
    
    [UIView setAnimationDelegate:self];
    
    myNavigationBar.alpha = alpha;
    myToolbar.alpha = alpha;
    
    [UIView commitAnimations];
}

- (void)_loadImage:(NSString*)path
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    UIImage * image = [[UIImage alloc] initWithContentsOfFile:path];
    CGImageRef image_ref = image.CGImage;
    
    @synchronized(self)
    {
	if (myScrolledImageView)
	{
	    [myScrolledImageView performSelectorOnMainThread:@selector(setImage:) 
						  withObject:(id)image_ref 
					       waitUntilDone:YES];
	    [image release];
	    
	    [mySpinner stopAnimating];
	    
	    if (!myScrolledImageView.image)
	    {
		// Setting the image failed, bail
		BriefcaseAppDelegate * delegate = [BriefcaseAppDelegate sharedAppDelegate];
		[delegate performSelectorOnMainThread:@selector(popFullScreenView) 
					   withObject:nil 
					waitUntilDone:YES];
	    }
	}
	else
	{
	    myStoredImage = image;
	}
    }
       
    [pool release];
}

@end
