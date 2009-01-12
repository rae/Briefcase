//
//  ChooseLocationController.m
//  Briefcase
//
//  Created by Michael Taylor on 21/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ChooseLocationController.h"
#import "SFTPSession.h"
#import "ConnectionController.h"
#import "SSHConnection.h"
#import "HostPrefs.h"
#import "SystemInformation.h"
#import "RemoteBrowserUtilities.h"
#import "IconManager.h"

NSString * kChooseLocationCell = @"Choose Location Cell";

@implementation ChooseLocationController

+ (void)chooseLocationWithNavigationController:(UINavigationController*)parent 
					target:(id)target 
				      selector:(SEL)action
{
    ConnectionController * connection_controller = [ConnectionController sharedController];
    if (!connection_controller.currentConnection)
	return;
    
    SSHConnection * ssh_connection = (SSHConnection*)connection_controller.currentConnection;
    SFTPSession * session = [ssh_connection getSFTPSession];
    
    NSString * root = nil;
    HostPrefs * prefs = [HostPrefs hostPrefsWithHostname:ssh_connection.hostName];
    if (prefs && !prefs.browseHomeDir)
    {
	SystemInformation * system_information = (SystemInformation*)ssh_connection.userData;
	if (system_information)
	    if (system_information.isConnectedToMac)
		root = @"/Volumes";
	    else
		root = @"/";
    }
    if (!root)
	root = [session canonicalizePath:@""];
    
    ChooseLocationController * controller;
    controller = [[ChooseLocationController alloc] initWithRemotePath:root
							       target:target 
							     selector:action 
							  sftpSession:session];
    [parent pushViewController:controller animated:YES];
    [controller release];
}

- (id)initWithRemotePath:(NSString*)remote_path 
		  target:(id)target 
		selector:(SEL)action 
	     sftpSession:(SFTPSession*)session
{
    self = [super init];
    if (self != nil) 
    {
	myTarget = [target retain];
	myAction = action;
	mySFTPSession = [session retain];
	myRemotePath = [remote_path retain];
    }
    return self;
}

- (void)_reloadDirectoryList
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    BOOL show_hidden = NO;
    HostPrefs * prefs = [HostPrefs hostPrefsWithHostname:mySFTPSession.connection.hostName];
    if (prefs && prefs.showHiddenFiles)
	show_hidden = YES;
    
    NSArray * items = [RemoteBrowserUtilities readRemoteDirectory:myRemotePath
						       showHidden:show_hidden
							showFiles:NO
						      sftpSession:mySFTPSession];

    NSMutableArray * directories = [NSMutableArray array];
    for (SFTPFileAttributes * attributes in items)
    {
	if (attributes.isDir)
	    [directories addObject:attributes.name];
    }
    
    @synchronized(self)
    {
	[myDirectoryList release];
	myDirectoryList = [directories retain];
    }
    
    [myTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    
    [pool release];
}

- (void)loadView 
{
    myTableView = [[UITableView alloc] init];
    myTableView.dataSource = self;
    myTableView.delegate = self;
    
    self.view = myTableView;
    
    [self performSelectorInBackground:@selector(_reloadDirectoryList) withObject:nil];
}

/*
// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
    [myTarget release];
    [mySFTPSession release];
    [myRemotePath release];
    [super dealloc];
}

#pragma mark Table View Data Source 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    @synchronized(self)
    {
	if (myDirectoryList)
	    return [myDirectoryList count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)index_path
{
    
    UITableViewCell * cell = [myTableView dequeueReusableCellWithIdentifier:kChooseLocationCell];
    if (cell == nil) 
    {
	cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kChooseLocationCell] autorelease];
	cell.image = [IconManager iconForFolderSmall:YES];
	cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    @synchronized(self)
    {
	cell.text = [myDirectoryList objectAtIndex:index_path.row];
    }
    
    return cell;
}

#pragma mark Table View Delegate 

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    // Push deeper one directory
    UINavigationController * navigation_controller = (UINavigationController*)self.parentViewController;
    ChooseLocationController * new_controller;
    NSString * new_path = [myRemotePath stringByAppendingPathComponent:[myDirectoryList objectAtIndex:indexPath.row]];
    new_controller = [[ChooseLocationController alloc] initWithRemotePath:new_path
								   target:myTarget 
								 selector:myAction
							      sftpSession:mySFTPSession];
    [navigation_controller pushViewController:new_controller animated:YES];
    [new_controller release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Call our callback
    NSString * result = [myRemotePath stringByAppendingPathComponent:[myDirectoryList objectAtIndex:indexPath.row]];
    [myTarget performSelector:myAction withObject:result];
    
    // Remove all of the choose location views from the navigation stack
    UINavigationController * navigation_controller = (UINavigationController*)self.parentViewController;
    NSEnumerator * enumerator = [navigation_controller.viewControllers reverseObjectEnumerator];
    for (UIViewController * controller in enumerator)
    {
	if (![controller isKindOfClass:[ChooseLocationController class]])
	{
	    [navigation_controller popToViewController:controller animated:YES];
	    break;
	}
    }
}

#pragma mark Properties

- (NSString*)remotePath
{
    return myRemotePath;
}

- (void)setRemotePath:(NSString*)path
{
    [myRemotePath release];
    myRemotePath = [path retain];
    
    [self performSelectorInBackground:@selector(_reloadDirectoryList) withObject:nil];
}

@end
