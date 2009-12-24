//
//  DocumentViewController.m
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
#import "RotatedControl.h"

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
        self.wantsFullScreenLayout = YES;
	
	myControlsHidden = NO;
        self.wantsFullScreenLayout = YES;

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
    [myHTML release];
    [super dealloc];
}

- (void)viewDidLoad 
{   
    myBookmarkField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth |
				 UIViewAutoresizingFlexibleHeight;
    
    myWebView.bounds = self.view.bounds;
    
    [self initExitFullScreenButton];
        
    [self adjustWebViewBounds];
}

- (void)loadView
{
    [super loadView];
    
    if (myFile)
	// Trigger the load of the URL
	[self setFile:myFile withHTML:myHTML];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque
                                                animated:YES];
    
    myViewingDocument = YES;
    myViewIsClosing = YES;
    
    // Listen for application termination
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self 
	       selector:@selector(appWillTerminate)
		   name:UIApplicationWillTerminateNotification
		 object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault
                                                animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    myViewingDocument = NO;
    
    // Save our location
    NSLog(@"Saving Book Location");
    myFile.lastViewLocation = self.documentPosition.y;
    [myFile save];
    
    if (myViewIsClosing)
    {
	[myFile release];
	myFile = nil;
	
	[myWebView stopLoading];
	
	// Load something trivial into the webview to clear out the
	// current document
	[myWebView loadHTMLString:@"<html></html>" baseURL:nil];
    }
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation) ||
        interfaceOrientation == UIInterfaceOrientationPortrait)
        return YES;
    else
        return NO;
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; 
}

- (void)_hideControls
{
    if (!self.controlsHidden)
	self.controlsHidden = YES;
}

- (void)appWillTerminate
{
    // Save the last viewing position in the file
    myFile.lastViewLocation = self.documentPosition.y;
    [myFile save];
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

- (void)setDocumentPosition:(LongPoint)position
{
    NSString * script = [NSString stringWithFormat:@"scrollDocument(%qi, %qi);", position.x, position.y];
    [myWebView stringByEvaluatingJavaScriptFromString:script];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Get the height of the document.  We'll delay to give the 
    // Web view time to get organized
    [self performSelector:@selector(determineDocumentHeight) withObject:nil afterDelay:1.0];
    
    // Load our Javascript helpers
    NSString * javascript_path;
    javascript_path = [[NSBundle mainBundle] pathForResource:@"DocumentViewController" 
                                                      ofType:@"js"];
    NSString * javascript = [NSString stringWithContentsOfFile:javascript_path
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];
    [myWebView stringByEvaluatingJavaScriptFromString:javascript];
    
    // Set the document position to the last position 
    // that was viewed
    self.documentPosition = LongPointMake(0, myFile.lastViewLocation);
    
    myLoadingView.hidden = YES;
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
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)determineDocumentHeight
{
    LongPoint current_pos = self.documentPosition;
    
    // Jump past the end of the document and see what the 
    // window position gets clamped to
    [myWebView stringByEvaluatingJavaScriptFromString:@"window.scrollTo(0,1000000000);"];
    LongPoint end_point = self.documentPosition;
    myDocumentHeight = end_point.y;
    
    self.documentPosition = current_pos;
}

#pragma mark Page Scroll HUD

- (void)updatePageScrollHUDTransformHidden:(BOOL)hidden 
                                   animate:(BOOL)animate
{
    CGRect parent_view_bounds = self.view.bounds;
    CGRect frame = myPageScrollHud.frame;
    
    frame.size.height = parent_view_bounds.size.height - (2.0 * kPageScrollHUDSidePadding);
    
    frame.origin.x = parent_view_bounds.origin.x + parent_view_bounds.size.width;
    
    if (!hidden)
        frame.origin.x -= frame.size.width + kPageScrollHUDSidePadding;
    
    frame.origin.y = kPageScrollHUDSidePadding;
    
    if (animate)
    {
	[UIView beginAnimations:@"HUD change" context:nil];
	[UIView setAnimationDuration:kPageScrollHUDAnimDuration];
	if (hidden)
	    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	else
	    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    }
    
    myPageScrollHud.frame = frame;
    
    if (animate)
	[UIView commitAnimations];
    
}

- (void)setUpPageScrollHUD
{
    mySrollViewHUDVisible = NO;
    
    UIImage * background = [UIImage imageNamed:@"page_scroll_hud.png"];
    background = [background stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    UIImageView * image_view = [[UIImageView alloc] initWithImage:background];
    
    CGRect frame = CGRectMake(0, 0, 60, 300);
    
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
    close_button.center = CGPointMake(myPageScrollHud.bounds.size.width / 2.0,
                                      myPageScrollHud.bounds.size.height - 
				      (close_button.bounds.size.height / 2.0) - 
				      (kPageScrollHUDPadding / 2.0) 
				      );
    [myPageScrollHud addSubview:close_button];
    
    RotatedControl * rotated_control = [[RotatedControl alloc] init];
    
    
    [myPageScrollHud addSubview:rotated_control];

    rotated_control.frame = CGRectMake(0, kPageScrollHUDPadding, 
                                       frame.size.width,
                                       frame.size.height - (2.0 * kPageScrollHUDPadding) - close_button.bounds.size.height 
                                      );
    
    myPageScrollSlider = [[UISlider alloc] init];
    myPageScrollSlider.center = CGPointMake(50, 150);
    myPageScrollSlider.transform = CGAffineTransformMake(0, 1, -1, 0, 0, 0);

    rotated_control.control = myPageScrollSlider;
    
    [self.view addSubview:myPageScrollHud];
    
    // Set up the resizing properties
    myPageScrollHud.autoresizesSubviews = YES;
    myPageScrollHud.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleHeight; 
    image_view.autoresizingMask      = UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight; 
    rotated_control.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin;
    close_button.autoresizingMask    = UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleTopMargin;
    
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
    
    myPageScrollSlider.value = (float)self.documentPosition.y / 
			       (float)myDocumentHeight;
    
    [self updatePageScrollHUDTransformHidden:YES animate:NO];
    [self updatePageScrollHUDTransformHidden:NO animate:YES];
    
    self.controlsHidden = YES;
    myExitFullScreenButton.alpha = 0.0;
//    [myEventMonitor endMonitoring];
}

- (void)hidePageScrollHUD
{
    [self updatePageScrollHUDTransformHidden:YES animate:YES];
    
    self.controlsHidden = NO;
//    [myEventMonitor beginMonitoring];
}

- (void)doPageScrollValueChanged
{
    float value = myPageScrollSlider.value;
    LongPoint position = self.documentPosition;
    position.y = (long long)((double)value * (double)myDocumentHeight);
    self.documentPosition = position;
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
	[self.navigationController popViewControllerAnimated:YES];
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
}

- (void)fadeOutBookmarkHud
{
    [myBookmarkField resignFirstResponder];
    
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
    
    myViewIsClosing = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString * position = NSStringFromLongPoint(self.documentPosition);
    NSArray * new_item = [NSArray arrayWithObjects:myBookmarkField.text, position, nil];
    myFile.bookmarks = [myFile.bookmarks arrayByAddingObject:new_item];
    [myFile save];
    
    [self fadeOutBookmarkHud];
    return YES;
}

#pragma mark Bookmark List Controller Delegate methods

- (void)bookmarkListControllerDone
{
    myViewIsClosing = YES;
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
	self.navigationItem.title = myFile.fileName;
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
    CGRect tool_bar_frame = myToolbar.frame;
    
    [[UIApplication sharedApplication] setStatusBarHidden:hidden animated:YES];
    [self.navigationController setNavigationBarHidden:hidden animated:YES];
    
    if (hidden)
	tool_bar_frame.origin.y = self.view.frame.size.height;
    else
	tool_bar_frame.origin.y = self.view.frame.size.height - tool_bar_frame.size.height;
    
    [UIView beginAnimations:@"Hide Document View Controls" context:NULL];
    
    [self adjustWebViewBounds];
    
    myToolbar.frame = tool_bar_frame;
    
    myExitFullScreenButton.alpha = 1.0 - alpha;
    
    [UIView commitAnimations];
}

- (LongPoint)documentPosition
{
    LongPoint result = LongPointZero;
    
    NSString * script = @"'{'+ window.pageXOffset + ',' + window.pageYOffset + '}'";
    NSString * script_result = [myWebView stringByEvaluatingJavaScriptFromString:script];
    if (script_result)
	result = LongPointFromNSString(script_result);
    
    return result;
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
	CGRect navigation_bar_frame = self.navigationController.navigationBar.frame;
	CGRect tool_bar_frame = myToolbar.frame;
	CGFloat status_bar_height = [UIApplication sharedApplication].statusBarFrame.size.height;
	offset = status_bar_height + navigation_bar_frame.size.height;
	bounds.size.height -= tool_bar_frame.size.height;
    }

    myWebView.frame = bounds;
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
    
    [self.view addSubview:myExitFullScreenButton];
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
    CGPoint position = [touch locationInView:self.view];
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
    CGRect parent_bounds = self.view.bounds;
    
    if (!CGRectContainsRect(self.view.bounds, frame))
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
    if (myExitFullScreenButton.frame.origin.x < self.view.frame.size.width / 2.0)
	mask |= UIViewAutoresizingFlexibleRightMargin;
    else
	mask |= UIViewAutoresizingFlexibleLeftMargin;
    
    if (myExitFullScreenButton.frame.origin.y < self.view.frame.size.height / 2.0)
	mask |= UIViewAutoresizingFlexibleBottomMargin;
    else
	mask |= UIViewAutoresizingFlexibleTopMargin;
    
    myExitFullScreenButton.autoresizingMask = mask;
}


@end
