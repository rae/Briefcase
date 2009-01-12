//
//  DirectoryViewController.h
//  Briefcase
//
//  Created by Michael Taylor on 06/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HostPrefs;

@protocol DirectoryViewDelegate

//- (void)itemSelected: (SFTPFileAttributes*)file atPath:(NSString*)path;

@end

@interface DirectoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> 
{
    NSString *			  myPath;
    NSArray *			  myDirectoryEntries;
    NSArray *			  myFilteredDirectoryEntries;
    IBOutlet UIView *		  myOptionView;
    IBOutlet UITableView *	  myTableView;
    IBOutlet UISwitch *		  myHiddenSwitch;
    IBOutlet UISegmentedControl * myBrowseRoot;
    IBOutlet UIView *		  mySpinnerView;
    
    UIBarButtonItem *		  myOptionsButton;
    UIBarButtonItem *		  myOptionsDoneButton;
    
    BOOL			  myViewInitialized;
}

@property (retain,nonatomic) NSString * path;
@property (retain,nonatomic) NSArray * directoryEntries;
@property (retain,nonatomic) UITableView * tableView;

+(void)setHostPrefsObject:(HostPrefs*)host_prefs;

-(id)initWithPath:(NSString*)path;

- (IBAction)showHiddenChanged:(id)sender;

- (void)hideOptionsAnimated:(BOOL)animated;

- (void)reset;

@end
