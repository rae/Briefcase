//
//  RemoteFileBrowserController.m
//  Briefcase
//
//  Created by Michael Taylor on 06/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "RemoteFileBrowserController.h"
#import "SFTPSession.h"
#import "DirectoryViewController.h"
#import "DirectoryReadOperation.h"
#import "ConnectionController.h"
#import "SFTPFileAttributes.h"
#import "NotConnectedController.h"
#import "NoIPhoneDownloadController.h"
#import "HostPrefs.h"
#import "SystemInformation.h"

static RemoteFileBrowserController * theRemoteFileBrowserController;

@implementation RemoteFileBrowserController

@synthesize navigationController = myNavigationController;
@synthesize sftpSession = mySFTPSession;

+ (RemoteFileBrowserController*)sharedController
{
    if (!theRemoteFileBrowserController)
	theRemoteFileBrowserController = [[RemoteFileBrowserController alloc] init];
    
    return theRemoteFileBrowserController;
}

- (id)init
{
    myDirectoryCache = [[NSMutableDictionary alloc] init];
    
    myRootDirectoryViewController = [[DirectoryViewController alloc] initWithPath:@"/"];
    myNotConnectedView = [[NotConnectedController alloc] init];
    myNoDownloadsView = [[NoIPhoneDownloadController alloc] init];
    
    myNavigationController = [UINavigationController alloc]; 
    [myNavigationController initWithRootViewController:myNotConnectedView];
    
    myOperationQueue = [[NSOperationQueue alloc] init];
    // Note that libssh isn't threadsafe anyway
    [myOperationQueue setMaxConcurrentOperationCount:1];
    
    // Listen for connection notifications
    NSNotificationCenter * notification_center;
    notification_center = [NSNotificationCenter defaultCenter];
    [notification_center addObserver:self 
			    selector:@selector(connectionEstablished:) 
				name:kMainConnectionEstablished 
			      object:nil];  
    [notification_center addObserver:self 
			    selector:@selector(connectionTerminated:) 
				name:kMainConnectionTerminated 
			      object:nil]; 
    
    return [super init];
}

- (void) dealloc
{
    [myRootDirectoryViewController release];
    [myDirectoryCache release];
    [myNavigationController release];
    [myOperationQueue release];
    [mySFTPSession release];
    // TODO release directory view controllers
    [super dealloc];
}

- (void)_resetTopView
{
    ConnectionController * connection_controller;
    connection_controller = [ConnectionController sharedController];
    
    if (connection_controller.currentConnection)
    {
	if (connection_controller.isInterBriefcaseConnection)
	    myNavigationController.viewControllers = [NSArray arrayWithObject:myNoDownloadsView];
	else
	    myNavigationController.viewControllers = [NSArray arrayWithObject:myRootDirectoryViewController];
    }
    else
    {
	myNavigationController.viewControllers = [NSArray arrayWithObject:myNotConnectedView];
    }
}

- (void)pushViewForPath:(NSString*)path
{
    // Start downloading the directory listing
    [self updateDirectoryCacheForPath:path];
    
    // Push a new directory view
    DirectoryViewController * new_controller;
    new_controller = [[DirectoryViewController alloc] initWithPath:path];
    [myNavigationController pushViewController:new_controller animated:YES];
    [new_controller release];
}

- (void)resetToRoot
{
    NSString * path;
    
    ConnectionController * connection_controller;
    connection_controller = [ConnectionController sharedController];
    if (connection_controller.currentConnection)
    {	
	[myNavigationController popToRootViewControllerAnimated:NO];
	
	// Look up the prefs for the host
	HostPrefs * host_prefs = [HostPrefs hostPrefsWithHostname:connection_controller.currentConnection.hostName];

	if (host_prefs.browseHomeDir)
	    path = [mySFTPSession canonicalizePath:@"."];
	else
	{
	    SystemInformation * system_information = connection_controller.currentConnection.userData;
	    if (system_information && system_information.isConnectedToMac)
		path = @"/Volumes";
	    else
		path = @"/";
	}
	
	myRootDirectoryViewController.path = path;
	myRootDirectoryViewController.directoryEntries = nil;
	
	// Start downloading the directory listing
	[self updateDirectoryCacheForPath:path];
	
	// Set the filtering options on the view
	[DirectoryViewController setHostPrefsObject:host_prefs];
    }
}

- (void)addDirectoryToCache:(NSString*)path withItems:(NSArray*)items
{
    @synchronized(myDirectoryCache)
    {
	[myDirectoryCache setObject:items forKey:path];
    }
    
    // Update the top view if necessary
    [self performSelectorOnMainThread:@selector(_updateViews) 
			   withObject:nil 
			waitUntilDone:NO];
}

- (void)directoryUpdateFailedForPath:(NSString*)path
{
    DirectoryViewController * top_controller = 
	(DirectoryViewController*)myNavigationController.topViewController;
    if ([path isEqualToString:top_controller.path])
	[myNavigationController popViewControllerAnimated:YES];
}

- (void)connectionEstablished:(NSNotification*)notification
{
    // Get an sftp session
    ConnectionController * connection_controller;
    connection_controller = [ConnectionController sharedController];

    if (!connection_controller.isInterBriefcaseConnection &&
	connection_controller.currentConnection)
    {
	mySFTPSession = [[connection_controller.currentConnection getSFTPSession] retain];
    }
    
    [self _resetTopView];
    [self resetToRoot];
}

- (void)connectionTerminated:(NSNotification*)notification
{
    [self _resetTopView];
    [myRootDirectoryViewController reset];
}

- (void)updateDirectoryCacheForPath:(NSString*)path
{
    DirectoryReadOperation * op = [[DirectoryReadOperation alloc] initWithPath:path];
    [myOperationQueue addOperation:op];
    [op release];
}

- (void)loadView:(DirectoryViewController*) fromPath:(NSString*)path
{
    
}

- (void)_updateViews
{
    if (![myNavigationController.topViewController isKindOfClass:[DirectoryViewController class]])
	return;
    
    DirectoryViewController * top_view;
    top_view = (DirectoryViewController*)myNavigationController.topViewController;
    NSArray * entries = [myDirectoryCache objectForKey:[top_view path]];
    top_view.directoryEntries = entries;
}
    
@end
