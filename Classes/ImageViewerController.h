//
//  ImageViewerController.h
//  navtest
//
//  Created by Michael Taylor on 14/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventMonitor.h"

@class DualViewController;
@class ScrolledImageView;
@class File;

@interface ImageViewerController : UIViewController <UINavigationBarDelegate, EventMonitorDelegate, UIActionSheetDelegate>
{
    IBOutlet DualViewController *	myDualNavController;
    IBOutlet ScrolledImageView *	myScrolledImageView;
    IBOutlet UINavigationBar *		myNavigationBar;
    IBOutlet UIToolbar *		myToolbar;
    IBOutlet UIActivityIndicatorView *	mySpinner;
    File *				myFile;
    UIDeviceOrientation			myImageViewOrientation;
    
    UIImage *				myStoredImage;
    
    EventMonitor *			myEventMonitor;
    
    BOOL				myIsDeleting;
}

@property (nonatomic,assign) BOOL controlsHidden;
@property (nonatomic,retain) DualViewController * dualNavigationController;

- (id)initWithFile:(File*)file;

- (IBAction)doImageAction;
- (IBAction)deleteFile;

@end
