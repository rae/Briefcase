//
//  FileViewController.m
//  Briefcase
//
//  Created by Michael Taylor on 08/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "DocumentViewController.h"
#import "BriefcaseAppDelegate.h"
#import "UploadActionController.h"
#import "BookmarkListController.h"
#import "File.h"

static NSString * kRotateDocument = @"Rotate Document";
static NSString * kDocumentViewerExitFullScreenPosition = @"Exit Full Screen Position";

static const NSTimeInterval kHideUIInterval	= 4.0;

static const float kPageScrollHUDPadding	= 25.0;
static const float kPageScrollHUDSidePadding	= 5.0;
static const float kPageScrollHudButtonAlpha	= 1.0;
static const float kPageScrollHUDAnimDuration	= 0.35;

static const float kExitFullScreenButtonRightMargin = 6.0;
static const float kExitFullScreenButtonTopMargin   = 28.0;

static DocumentViewController * theDocumentViewController = nil;

@interface DocumentViewController (Private)

- (void)adjustWebViewBounds;

- (void)initExitFullScreenButton;
- (CGRect)clipFrameToBounds:(CGRect)frame;
- (void)adjustFullScreenExitButtonResizingMask;

@end

@implementation DocumentViewController

+ (DocumentViewController*)documentViewControllerForFile:(File*)file
{
    if (!theDocumentViewController)
	theDocumentViewController = [[DocumentViewController alloc] init];
    
    theDocumentViewController.file = file;
    return theDocumentViewController;
}


+ (DocumentViewController*)documentViewControllerForFile:(File*)file withHTML:(NSString*)html
{
    if (!theDocumentViewController)
	theDocumentViewController = [[DocumentViewController alloc] init];
    
    [theDocumentViewController setFile:file withHTML:html];

    return theDocumentViewController;
}


- (id)retain
{
    return [super retain];
}

- (id)init
{
    if (self = [super initWithNibName:@"DocumentView" bundle:nil]) 
    {
	myViewingDocument = NO;
	self.hidesBottomBarWhenPushed = YES;
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(orientationDidChange:) 
		       name:UIDeviceOrientationDidChangeNotification
		     object:nil];
	
	[center addObserver:self selector:@selector(applicationTerminating:) 
		       name:kFileDatabaseWillFinalize 
		     object:nil];
	
	myControlsHidden = NO;
	
	// Set up the event monitor that helps us to know when
	// to hide the UI
//	myEventMonitor = [[EventMonitor alloc] init];
//	myEventMonitor.delegate = self;
//	myEventMonitor.idleEventDelay = kHideUIInterval;

	UIImage * button_image = [UIImage imageNamed:@"enter_fullscreen.png"];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:button_image 
										  style:UIBarButtonItemStylePlain
										 target:self 
										action:@selector(_hideControls)];
    }
    return self;
}

- (void)dealloc 
{ 
    [myPageScrollHud release];
    [myPageScrollSlider release];
    [myFile release];
    [myEventMonitor release];
    [myHTML release];
    [super dealloc];
}

- (void)viewDidLoad 
{   
    UINavigationItem * item = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Files", @"Title for back button")];
    
    [myNavigationBar pushNavigationItem:item animated:NO];
    [myNavigationBar pushNavigationItem:self.navigationItem animated:NO];
    
    myNavigationBar.delegate = self;
    
    myBookmarkField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    myWebParent.autoresizesSubviews = YES;
    myWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
				 UIViewAutoresizingFlexibleHeight;
    
    [self initExitFullScreenButton];
    
    myWebViewOrientation = UIDeviceOrientationPortrait;
    myWebParent.center = CGPointMake(0.0, 0.0);
    
    [self adjustWebViewBounds];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    // Save our location
    myFile.lastViewLocation = self.documentPosition;
    [myFile save];
    
    [[BriefcaseAppDelegate sharedAppDelegate] popFullScreenView];
    
    // Load something trivial into the webview to clear out the
    // current document
    [myWebView loadHTMLString:@"<html></html>" baseURL:nil];
    
    return NO;
}

- (void)loadView
{
    [super loadView];
    
    if (myFile)
	// Trigger the load of the URL
	[self setFile:myFile withHTML:myHTML];
    
    myEventMonitor.viewToMonitor = [[myWebView hitTest:self.view.center withEvent:nil] retain];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    myViewingDocument = YES;
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [myEventMonitor endMonitoring];
    
    myViewingDocument = NO;
}

- (void)orientationDidChange:(NSNotification*)notification
{
    long long rotation_location = self.documentPosition;
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if (orientation == myWebViewOrientation || 
	orientation == UIDeviceOrientationFaceUp ||
	orientation == UIDeviceOrientationFaceDown) return;
    
    myWebViewOrientation = orientation;
    
    [UIView beginAnimations:kRotateDocument context:nil];
    
    [self adjustWebViewBounds];
    
    [UIView commitAnimations];    
        
    self.documentPosition = rotation_location;
}

- (void)applicationTerminating:(NSNotification*)notification
{
    // Save the current document viewing position
    myFile.lastViewLocation = self.documentPosition;
    [myFile save];
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; 

//    if (!myViewingDocument) return;
//    
//    // Bail
//    [myWebView stopLoading];
//    [[BriefcaseAppDelegate sharedAppDelegate] popFullScreenView];
//    
//    UIAlertView * server_alert;
//    server_alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Low Memory", @"Title for dialog telling the user that we ran out of memory") 
//					      message:NSLocalizedString(@"Out of memory. Closing document", @"Message to user saying that we had to close their document because of a low memory situation") 
//					     delegate:self 
//				    cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button")
//				    otherButtonTitles:nil];
//    
//    [server_alert show];
//    [server_alert release];
}

- (void)_hideControls
{
    if (!self.controlsHidden)
	self.controlsHidden = YES;
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

#pragma mark UIWebView Delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Get the height of the document.  We'll delay to give the 
    // Web view time to get organized
    [self performSelector:@selector(determineDocumentHeight) withObject:nil afterDelay:1.0];
    
    // Set the document position to the last position 
    // that was viewed
    self.documentPosition = myFile.lastViewLocation;
    
    myLoadingView.hidden = YES;
    
    // Start monitoring touch events
//    [myEventMonitor beginMonitoring];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Error: %@",[error localizedDescription]);
    NSLog(@"Error: %@",[error localizedFailureReason]);
    NSLog(@"Error: %@",[error localizedRecoverySuggestion]);
    
    UIAlertView * server_alert;
        
    NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Viewing of document \"%@\" is not supported on this device", @"Error message displayed when Briefcase cannot display a document"),
			  myFile.fileName];
    
    server_alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"View Document Error",@"Title for error message that occurs when Briefcase cannot display a document") 
					      message:message
					     delegate:self 
				    cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label")
				    otherButtonTitles:nil];
    
    [server_alert show];
    [[BriefcaseAppDelegate sharedAppDelegate] popFullScreenView];
}

- (void)determineDocumentHeight
{
    long long current_pos = self.documentPosition;
    
    // Jump past the end of the document and see what the 
    // window position gets clamped to
    [myWebView stringByEvaluatingJavaScriptFromString:@"window.scrollTo(0,1000000000);"];
    myDocumentHeight = self.documentPosition;
    
    self.documentPosition = current_pos;
}

#pragma mark Page Scroll HUD

- (void)setPageScrollHUDTransformVertical:(BOOL)vertical 
				   hidden:(BOOL)hidden 
				  animate:(BOOL)animate
{
    CGAffineTransform transform;
    
    if (vertical)
    {
	CGPoint translation;
	translation.x = floorf(self.view.frame.size.width - (myPageScrollHud.bounds.size.height / 2.0) - kPageScrollHUDSidePadding);
	translation.y = floorf(self.view.frame.size.height  / 2.0);
	
	if (hidden)
	    translation.x += myPageScrollHud.bounds.size.height + kPageScrollHUDSidePadding;
	
	transform = CGAffineTransformMakeTranslation(translation.x, translation.y);
	
	// 90 degree rotation
	CGAffineTransform rotation = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
	transform = CGAffineTransformConcat(rotation, transform);
	
    }
    
    
    if (animate)
    {
	[UIView beginAnimations:@"HUD change" context:nil];
	[UIView setAnimationDuration:kPageScrollHUDAnimDuration];
	if (hidden)
	    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	else
	    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    }
    
    myPageScrollHud.transform = transform;
    
    if (animate)
	[UIView commitAnimations];
    
}

- (void)setUpPageScrollHUD
{
    mySrollViewHUDVisible = NO;
    
    UIImage * background = [UIImage imageNamed:@"page_scroll_hud.png"];
    UIImageView * image_view = [[UIImageView alloc] initWithImage:background];
    
    CGRect frame = CGRectZero;
    frame.size = background.size;
    
    image_view.frame = frame;
    
    myPageScrollHud = [[UIView alloc] init];
    [myPageScrollHud addSubview:image_view];
    [image_view release];
    
    myPageScrollHud.bounds = frame;

    UIButton * close_button = [UIButton buttonWithType:UIButtonTypeCustom];
    [close_button setImage:[UIImage imageNamed:@"closebox.png"] 
		  forState:UIControlStateNormal];
    [close_button sizeToFit];
    close_button.alpha = kPageScrollHudButtonAlpha;
    close_button.center = CGPointMake(myPageScrollHud.bounds.size.width - 
				      (close_button.bounds.size.width / 2.0) - 
				      (kPageScrollHUDPadding / 2.0), 
				      myPageScrollHud.bounds.size.height / 2.0);
    [myPageScrollHud addSubview:close_button];
    
    myPageScrollSlider = [[UISlider alloc] init];
    [myPageScrollHud addSubview:myPageScrollSlider];

    myPageScrollSlider.frame = CGRectMake(kPageScrollHUDPadding, 
					  kPageScrollHUDPadding, 
					  frame.size.width - (2.0 * kPageScrollHUDPadding) - close_button.bounds.size.width, 
					  frame.size.height - (2.0 * kPageScrollHUDPadding));

    [self.view addSubview:myPageScrollHud];
    
    // Set up the callbacks
    [close_button addTarget:self 
		     action:@selector(hidePageScrollHUD) 
	   forControlEvents:UIControlEventTouchUpInside];
    
    [myPageScrollSlider addTarget:self 
			   action:@selector(doPageScrollValueChanged) 
		 forControlEvents:UIControlEventValueChanged];
    [myPageScrollSlider setMinimumValue:0.0];
    [myPageScrollSlider setMaximumValue:1.0];
}

- (IBAction)doPageScroll
{
    if (!myPageScrollHud)
	[self setUpPageScrollHUD];
    
    myPageScrollSlider.value = (float)self.documentPosition / 
			       (float)myDocumentHeight;
    
    [self setPageScrollHUDTransformVertical:YES hidden:YES animate:NO];
    [self setPageScrollHUDTransformVertical:YES hidden:NO animate:YES];
    
    self.controlsHidden = YES;
//    [myEventMonitor endMonitoring];
}

- (void)hidePageScrollHUD
{
    [self setPageScrollHUDTransformVertical:YES hidden:YES animate:YES];
    
    self.controlsHidden = NO;
//    [myEventMonitor beginMonitoring];
}

- (void)doPageScrollValueChanged
{
    float value = myPageScrollSlider.value;
    self.documentPosition = (long long)((double)value * (double)myDocumentHeight);
}

- (IBAction)deleteFile
{
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil 
							delegate:self 
					       cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label")
					  destructiveButtonTitle:NSLocalizedString(@"Delete Document",@"Delete a document from Briefcase") 
					       otherButtonTitles:nil
			     ];
    [sheet showFromToolbar:myToolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
	[myFile delete];
	[[BriefcaseAppDelegate sharedAppDelegate] popFullScreenView];
    }
}

#pragma mark Bookmarks

- (IBAction)doAddBookmark
{
    NSString * bookmark_string = [NSString stringWithFormat:NSLocalizedString(@"My Bookmark%d",@"Placeholder for a bookmark name.  It is tagged with a number"),
				  [myFile.bookmarks count] + 1];
    myBookmarkField.text = bookmark_string;
    
    myBookmarkHud.alpha = 0.0;
    myBookmarkHud.hidden = NO;
    
    [UIView beginAnimations:@"Hud fade" context:nil];
    
    myBookmarkHud.alpha = 1.0;
    
    [UIView commitAnimations];
    
    [myBookmarkField becomeFirstResponder];
    
    UINavigationItem * nav_item = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Add Bookmark",@"Title for add bookmark view")];
    nav_item.hidesBackButton = YES;
    UIBarButtonItem * item;
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
							 target:self 
							 action:@selector(cancelBookmark)];
    nav_item.leftBarButtonItem = item;
    [myNavigationBar pushNavigationItem:nav_item animated:NO];
}

- (void)fadeOutBookmarkHud
{
    [myBookmarkField resignFirstResponder];
    
    myNavigationBar.items = [NSArray arrayWithObjects:
			     [myNavigationBar.items objectAtIndex:0],
			     [myNavigationBar.items objectAtIndex:1],
			     nil];
    
    [UIView beginAnimations:@"Hud fade" context:nil];
    
    myBookmarkHud.alpha = 0.0;
    
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(hudFadeDone)];
    [UIView commitAnimations];
}

- (void)bookmarkHudFadeDone
{
    myBookmarkHud.hidden = YES;
}

- (void)cancelBookmark
{
    [self fadeOutBookmarkHud];
}

- (void)doShowBookmarks
{    
    BookmarkListController * controller = [[BookmarkListController alloc] initWithFile:myFile];
    controller.delegate = self;
    [self presentModalViewController:controller animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSNumber * position = [NSNumber numberWithLongLong:self.documentPosition];
    NSArray * new_item = [NSArray arrayWithObjects:myBookmarkField.text, position, nil];
    myFile.bookmarks = [myFile.bookmarks arrayByAddingObject:new_item];
    [myFile save];
    
    [self fadeOutBookmarkHud];
    return YES;
}

#pragma mark Properties

- (File*)file
{
    return myFile;
}

- (void)setFile:(File*)file
{
    [self setFile:file withHTML:nil];
}

- (void)setFile:(File*)file withHTML:(NSString*)html
{
    [myFile release];
    [myHTML release];
    myFile = [file retain];
    myHTML = [html retain];
    
    if (file && myWebView)
    {
	if (html)
	{
	    NSString * base_url_string = [file.localPath stringByDeletingLastPathComponent];
	    NSURL * base_url = [NSURL fileURLWithPath:base_url_string];
	    
	    [myWebView loadHTMLString:html baseURL:base_url];
	}
	else
	{
	    NSData * webarchive = file.webArchiveData;
	    if (webarchive)
	    {
		[myWebView loadData:webarchive 
			   MIMEType:@"application/x-webarchive" 
		   textEncodingName:@"utf-8" 
			    baseURL:[NSURL fileURLWithPath:[file.localPath stringByDeletingLastPathComponent]]];
	    }
	    else
	    {
		NSURL * url = [NSURL fileURLWithPath:myFile.path];
		NSLog(@"Path: %@", myFile.path);
		NSURLRequest * request = [NSURLRequest requestWithURL:url];
		[myWebView loadRequest:request];
	    }
	}
	myLoadingView.hidden = NO;
    }
}

- (BOOL)controlsHidden
{
    return myControlsHidden;
}

- (void)setControlsHidden:(BOOL)hidden
{
    myControlsHidden = hidden;
    
    CGFloat alpha = hidden ? 0.0 : 1.0;
    
    CGRect navigation_bar_frame = myNavigationBar.frame;
    CGRect tool_bar_frame = myToolbar.frame;
    
    UIApplication * app = [UIApplication sharedApplication];
    
    [[UIApplication sharedApplication] setStatusBarHidden:hidden animated:YES];
    
    if (hidden)
    {
	navigation_bar_frame.origin.y = -navigation_bar_frame.size.height;
	tool_bar_frame.origin.y = self.view.frame.size.height;
    }
    else
    {
	navigation_bar_frame.origin.y = app.statusBarFrame.size.height;
	tool_bar_frame.origin.y = self.view.frame.size.height - tool_bar_frame.size.height;
    }
    
    [UIView beginAnimations:@"Hide Document View Controls" context:NULL];
    
    [self adjustWebViewBounds];
    
    myNavigationBar.frame = navigation_bar_frame;
    myToolbar.frame = tool_bar_frame;
    
    myExitFullScreenButton.alpha = 1.0 - alpha;
    
    [UIView commitAnimations];
}

- (long long)documentPosition
{
    long long result = 0;
    
    NSString * script_result = [myWebView stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"];
    if (script_result)
    {
	NSScanner * scanner = [NSScanner scannerWithString:script_result];
	if(![scanner scanLongLong:&result])
	    result = 0;
    }
    
    return result;
}

- (void)setDocumentPosition:(long long)position
{
    NSString * script = [NSString stringWithFormat:@"window.scrollTo(0, %qi);", position];
    [myWebView stringByEvaluatingJavaScriptFromString:script];
}

@end

@implementation DocumentViewController (Private)

- (void)adjustWebViewBounds
{
    CGFloat offset = 0.0;
    CGRect bounds = self.view.bounds;
    
    // If our UI is visible, adjust for that
    if (!myControlsHidden)
    {
	CGRect navigation_bar_frame = myNavigationBar.frame;
	CGRect tool_bar_frame = myToolbar.frame;
	CGFloat status_bar_height = [UIApplication sharedApplication].statusBarFrame.size.height;
	offset = status_bar_height + navigation_bar_frame.size.height;
	bounds.size.height -= offset + tool_bar_frame.size.height;
    }
    
    CGFloat half_height = bounds.size.height / 2.0;
    CGFloat half_width  = bounds.size.width  / 2.0;
    
    CGAffineTransform rotation;
    switch (myWebViewOrientation) 
    {
	case UIDeviceOrientationPortrait:
	    rotation = CGAffineTransformMake(1, 0, 0, 1, half_width, 
					     half_height + offset);
	    bounds = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
	    break;
	case UIDeviceOrientationPortraitUpsideDown:
	    rotation = CGAffineTransformMake(-1, 0, 0, -1, half_width, 
					     half_height + offset);
	    bounds = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
	    break;
	case UIDeviceOrientationLandscapeLeft:
	    rotation = CGAffineTransformMake(0, 1, -1, 0, half_width, 
					     half_height + offset);
	    bounds = CGRectMake(0, 0, bounds.size.height, bounds.size.width);
	    break;
	case UIDeviceOrientationLandscapeRight:
	    rotation = CGAffineTransformMake(0, -1, 1, 0, half_width, 
					     half_height + offset);
	    bounds = CGRectMake(0, 0, bounds.size.height, bounds.size.width);
	    break;
	default:
	    // Ignore any other orientations
	    return;
    }
    
    myWebParent.transform = rotation;
    myWebParent.bounds = bounds;
    
    [myWebParent setNeedsLayout];
}

#pragma mark Exit Fullscreen Button

- (void)initExitFullScreenButton
{
    UIImage * exit_image = [UIImage imageNamed:@"exit_fullscreen.png"];
    
    NSUserDefaults * standard_defaults = [NSUserDefaults standardUserDefaults];
    NSString * position_string = [standard_defaults stringForKey:kDocumentViewerExitFullScreenPosition];
    CGRect frame;
    
    if (!position_string)
    {
	CGSize view_size = self.view.bounds.size;
	frame = CGRectMake(view_size.width - exit_image.size.width - kExitFullScreenButtonRightMargin, 
			   kExitFullScreenButtonTopMargin, 
			   exit_image.size.width, exit_image.size.height);
    }
    else
    {
	CGPoint point = CGPointFromString(position_string);
	frame = CGRectMake(point.x, point.y,
			   exit_image.size.width, exit_image.size.height);
	frame = [self clipFrameToBounds:frame];
    }

    myExitFullScreenButton = [[UIButton alloc] initWithFrame:frame];
    [myExitFullScreenButton setImage:exit_image forState:UIControlStateNormal];
    myExitFullScreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
					      UIViewAutoresizingFlexibleBottomMargin;
    myExitFullScreenButton.alpha = 0.0;
    
    [myWebParent addSubview:myExitFullScreenButton];
    [self adjustFullScreenExitButtonResizingMask];
    
    [myExitFullScreenButton addTarget:self 
			       action:@selector(fullScreenButtonDragged:forEvent:) 
		     forControlEvents:UIControlEventTouchDragInside|UIControlEventTouchDragOutside];
    [myExitFullScreenButton addTarget:self 
			       action:@selector(fullScreenButtonTouchDown:) 
		     forControlEvents:UIControlEventTouchDown];
    [myExitFullScreenButton addTarget:self 
			       action:@selector(fullScreenButtonTouchUp:) 
		     forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
}

- (void)fullScreenButtonTouchDown:(id)sender
{
    myExitFullScreenButtonDragged = NO;
}

- (void)fullScreenButtonDragged:(id)sender forEvent:(UIEvent *)event
{
    UITouch * touch = [[event allTouches] anyObject];
    CGPoint position = [touch locationInView:myWebParent];
    CGPoint button_center = myExitFullScreenButton.center;
    
    float x = position.x - button_center.x;
    float y = position.y - button_center.y;
    
    if (myExitFullScreenButtonDragged || sqrtf(x*x + y*y) > 4.0)
    {
	myExitFullScreenButtonDragged = YES;
	myExitFullScreenButton.center = position;
	myExitFullScreenButton.frame = [self clipFrameToBounds:myExitFullScreenButton.frame];
	
	[self adjustFullScreenExitButtonResizingMask];
    }
}

- (void)fullScreenButtonTouchUp:(id)sender
{
    if (myExitFullScreenButtonDragged)
    {
	// Save the new position of the button in our prefs
	NSUserDefaults * standard_defaults = [NSUserDefaults standardUserDefaults];
	NSString * position_string = NSStringFromCGPoint(myExitFullScreenButton.frame.origin);
	[standard_defaults setObject:position_string forKey:kDocumentViewerExitFullScreenPosition];
    }
    else
    {
	// Show the UI
	self.controlsHidden = NO;
    }
}

- (CGRect)clipFrameToBounds:(CGRect)frame
{
    CGRect result = frame;
    CGRect parent_bounds = myWebParent.bounds;
    
    if (!CGRectContainsRect(myWebParent.bounds, frame))
    {
	if (CGRectGetMinX(frame) < CGRectGetMinX(parent_bounds))
	    result.origin.x = parent_bounds.origin.x;
	if (CGRectGetMinY(frame) < CGRectGetMinY(parent_bounds))
	    result.origin.y = parent_bounds.origin.y;
	if (CGRectGetMaxX(frame) > CGRectGetMaxX(parent_bounds))
	    result.origin.x = parent_bounds.origin.x + parent_bounds.size.width - frame.size.width;
	if (CGRectGetMaxY(frame) > CGRectGetMaxY(parent_bounds))
	    result.origin.y = parent_bounds.origin.y + parent_bounds.size.height - frame.size.height;
    }
    
    return result;
}

- (void)adjustFullScreenExitButtonResizingMask
{
    // Make the exit button stick to the sides of the view it is closest too
    UIViewAutoresizing mask = UIViewAutoresizingNone;
    if (myExitFullScreenButton.frame.origin.x < myWebParent.frame.size.width / 2.0)
	mask |= UIViewAutoresizingFlexibleRightMargin;
    else
	mask |= UIViewAutoresizingFlexibleLeftMargin;
    
    if (myExitFullScreenButton.frame.origin.y < myWebParent.frame.size.height / 2.0)
	mask |= UIViewAutoresizingFlexibleBottomMargin;
    else
	mask |= UIViewAutoresizingFlexibleTopMargin;
    
    myExitFullScreenButton.autoresizingMask = mask;
}


@end
