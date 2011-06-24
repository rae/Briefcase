//
//  SettingsViewController.h
//  Briefcase
//
//  Created by Michael Taylor on 10-01-30.
//  Copyright 2010 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface SettingsViewController : UITableViewController <MFMailComposeViewControllerDelegate> {

}

+ (SettingsViewController*)sharedController;

@end
