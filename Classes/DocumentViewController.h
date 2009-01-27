//
//  FileViewController.h
//  Briefcase
//
//  Created by Michael Taylor on 08/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BookmarkListController.h"
#import "EventMonitor.h"
#import "Utilities.h"

@class File;

@interface DocumentViewController : UIViewController <UITextFieldDelegate, BookmarkListControllerDelegate, UIWebViewDelegate, EventMonitorDelegate, UIActionSheetDelegate> 
{
    IBOutlet UIWebView *	myWebView;
    IBOutlet UIView *		myWebParent;
    IBOutlet UIToolbar *	myToolbar;
    IBOutlet UINavigationBar *	myNavigationBar;
    BOOL			myControlsHidden;
    
    IBOutlet UIView *		myBookmarkHud;
    IBOutlet UITextField *	myBookmarkField;
    
    IBOutlet UIView *		myLoadingView;
    
    UIView *			myPageScrollHud;
    UISlider *			myPageScrollSlider;
    BOOL			mySrollViewHUDVisible;
    
    UIButton *			myExitFullScreenButton;
    BOOL			myExitFullScreenButtonDragged;
    
    UIDeviceOrientation		myWebViewOrientation;
    
    EventMonitor *		myEventMonitor;
    
    File *			myFile;
    NSString *			myHTML;
    
    long long			myDocumentHeight;
    
    BOOL			myViewingDocument;
    BOOL			myViewIsClosing;
}

@property (nonatomic,assign) LongPoint	documentPosition;
@property (nonatomic,assign) BOOL	controlsHidden;
@property (nonatomic,retain) File *	file;

+ (DocumentViewController*)documentViewControllerForFile:(File*)file;
+ (DocumentViewController*)documentViewControllerForFile:(File*)file withHTML:(NSString*)html;

- (void)setFile:(File*)file withHTML:(NSString*)html;

- (IBAction)doAddBookmark;
- (IBAction)doShowBookmarks;

- (IBAction)doPageScroll;

- (IBAction)deleteFile;

@end
