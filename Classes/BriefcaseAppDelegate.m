//
//  BriefcaseAppDelegate.m
//  Briefcase
//
//  Created by Michael Taylor on 01/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BriefcaseAppDelegate.h"
#import "RotatableTabController.h"
#import "ConnectionController.h"
#import "SystemInfoController.h"
#import "RemoteFileBrowserController.h"
#import "UploadActionController.h"
#import "ActivityViewController.h"
#import "File.h"
#import "DownloadController.h"
#import "BriefcaseServer.h"
#import "FreeSpaceController.h"
#import "KeychainItem.h"
#import "HMCrashHandler.h"

@implementation BriefcaseAppDelegate

@synthesize portraitWindow;
@synthesize tabController;
@synthesize connectionController;

static BriefcaseAppDelegate * theSharedAppDelegate;

+ (BriefcaseAppDelegate*)sharedAppDelegate
{
    return theSharedAppDelegate;
}

- (id)init {
    if (self = [super init]) {
	// initialize  to nil
	portraitWindow = nil;
	tabController = nil;
    }
    theSharedAppDelegate = self;
    return self;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{	    
    // Set the status bar
    [application setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    
    // Initialize the our database
    [File initializeFileDatabase];
    
    // Create main window
    CGRect bounds = [[UIScreen mainScreen] bounds];
    self.portraitWindow = [[[UIWindow alloc] initWithFrame:bounds] autorelease];
    
    [self.portraitWindow setBackgroundColor:[UIColor blackColor]];
    
    // Set up the tabs
    self.tabController = [[RotatableTabController alloc] init];
        
    NSMutableArray * view_controller_array = [[NSMutableArray alloc] initWithCapacity:1];
    
    // Views for managing connection to a Mac
    [view_controller_array addObject:[self createConnectViews]];
    
    // Views for getting files
    [view_controller_array addObject:[self createDownloadViews]];
    
    // Views for putting files
    [view_controller_array addObject:[self createUploadViews]];
    
    // Views for monitoring activity
    [view_controller_array addObject:[self createActivityViews]];
    
    self.tabController.viewControllers = view_controller_array;
    [view_controller_array release];
    
    [self.portraitWindow addSubview:self.tabController.view];
    [self.portraitWindow makeKeyAndVisible];
    
    // Resume any incomplete downloads
    [[DownloadController sharedController] resumeIncompleteDownloads];
    
    // Start the server
    BriefcaseServer * server;
    server = [BriefcaseServer sharedController];
    [server startServer];
    
    // Cause Briefcase to update space used by downloaded files
    [FreeSpaceController sharedController];
    
    // Register for callback if a fresh database is created
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(firstTimeInitialization:) 
		   name:kFileDatabaseCreated object:nil];
    
    // Upload crash reports if available
    HMCrashHandler * crash_handler = [HMCrashHandler sharedHandler];
    [crash_handler handlePendingCrashReports];
    [crash_handler pingServer];
}

- (void)applicationWillTerminate:(UIApplication *)application 
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    [Database finalizeDatabase];
}

- (void)firstTimeInitialization:(NSNotification*)notification
{
    [KeychainItem cleanKeychain];
}

- (UIViewController*)createConnectViews
//
// Set up view for determining a machine to connect to
//
{
    connectionController = [ConnectionController sharedController];
    UINavigationController * nav_controller;
    nav_controller = [[UINavigationController alloc] initWithRootViewController:connectionController];
    nav_controller.tabBarItem.image = [UIImage imageNamed:@"connect_gray.png"];
    nav_controller.tabBarItem.title = NSLocalizedString(@"Connect", @"Connect title");
    nav_controller.delegate = connectionController;
    connectionController.navigationController = nav_controller;
    return nav_controller;
}

- (UIViewController*)createDownloadViews
{
    RemoteFileBrowserController * sharedController;
    sharedController = [RemoteFileBrowserController sharedController];
    
    UIViewController * result = sharedController.navigationController;
    result.tabBarItem.image = [UIImage imageNamed:@"download_gray.png"];
    result.tabBarItem.title = NSLocalizedString(@"Get File", @"Download title");
    return result;
}

- (UIViewController*)createUploadViews
{
    UploadActionController * upload_action_controller;
    upload_action_controller = [UploadActionController sharedController];
            
    UIViewController * result = upload_action_controller.navigationController;
    result.tabBarItem.image = [UIImage imageNamed:@"briefcase_gray.png"];
    result.tabBarItem.title = NSLocalizedString(@"Files", @"Briefcase title");
    return result;
}

- (UIViewController*)createActivityViews
{
    UIViewController * result = [ActivityViewController navigationController];
    result.tabBarItem.image = [UIImage imageNamed:@"activity_gray.png"];
    result.tabBarItem.title = NSLocalizedString(@"Activity", @"Activity title");
    return result;
}

- (void)gotoConnectTab
{
    tabController.selectedIndex = 0;
}

- (void)dealloc 
{
    [connectionController release];
    [self.portraitWindow release];
    [self.tabController release];
    [super dealloc];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // We the app wakes up, check any connections
    
    ConnectionController * controller = [ConnectionController sharedController];
    if (controller.currentConnection  && !controller.currentConnection.isConnected)
    {
	[controller.currentConnection disconnect];
    }
}


@end
