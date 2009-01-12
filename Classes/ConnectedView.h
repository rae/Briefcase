//
//  ConnectedView.h
//  Briefcase
//
//  Created by Michael Taylor on 27/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GradientView.h"

@interface ConnectedView : GradientView {
    UIImageView *	    myBriefcaseLogoView;
    UIImageView *	    myBriefcaseTextView;
    UIImageView *	    myBinaryTextView;
    
    NSString *		    myHostName;
    UIFont *		    myHostNameFont;
    CGPoint		    myHostNameLocation;
    
    IBOutlet UIButton *	    myDisclosureButton;
    IBOutlet UIImageView *  myHostIconImageView;
    
    IBOutlet UIView *	    myDisconnectView;
    IBOutlet UIView *	    myConnectingView;
    
    BOOL		    myIsInitialized;
}

@property (nonatomic,retain) NSString * hostName;
@property (nonatomic,retain) UIImage *	hostIcon;

- (void)resetViewAnimated:(BOOL)animated;
- (void)setConnected:(BOOL)connected;

@end
