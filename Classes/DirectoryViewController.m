//
//  DirectoryViewController.m
//  Briefcase
//
//  Created by Michael Taylor on 06/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "DirectoryViewController.h"
#import "RemoteFileBrowserController.h"
#import "SFTPFileAttributes.h"
#import "DownloadController.h"
#import "DirectoryDownloadCell.h"
#import "IconManager.h"
#import "HostPrefs.h"
#import "NetworkOperation.h"
#import "FreeSpaceController.h"
#import "Utilities.h"
#import "RemoteBrowserUtilities.h"

NSMutableDictionary * theActiveDownloads = nil;

#define kSpinnerDelay 0.5

#define FLOATRGBA(A,B,C) colorWithRed:((CGFloat)A/255.0) green:((CGFloat)B/255.0) blue:((CGFloat)C/255.0) alpha:1.0

// View Gradient
#define kCellBackgroundColor		FLOATRGBA(222, 222, 227)


@implementation DirectoryViewController

@synthesize path = myPath;
@synthesize tableView = myTableView;
@dynamic directoryEntries;

#define kDirectoryCell @"Directory Cell"
#define kDownloadDirectoryCell @"Download Directory Cell"

static HostPrefs *  theHostPrefs = nil;

+(void)setHostPrefsObject:(HostPrefs*)host_prefs
{
    [theHostPrefs release];
    theHostPrefs = [host_prefs retain];
}

- (id)initWithPath:(NSString*)path {
    if (self = [super initWithNibName:@"DirectoryView" bundle:nil]) 
    {
	myDirectoryEntries = nil;
	myFilteredDirectoryEntries = nil;
	
	myPath = [path retain];
	
	if ([myPath compare:@"/"] == NSOrderedSame)
	    self.title = @"/";
	else
	    self.title = [path lastPathComponent];
	
	self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Parent", @"Title of back button when file browsing.  Refers the the parent directory");
	
	myOptionsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Options", @"Label for button that displays the UI for setting the file browsing options") 
							   style:UIBarButtonItemStylePlain 
							  target:self 
							  action:@selector(showOptions)];
	myOptionsDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
							  target:self 
							  action:@selector(hideOptions)];
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(downloadFinished:) 
		       name:kNetworkOperationEnd 
		     object:nil];
	
	myViewInitialized = NO;
    }
    
    if (!theActiveDownloads)
	theActiveDownloads = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void) dealloc
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
    
    [myPath release];
    [myDirectoryEntries release];
    [myFilteredDirectoryEntries release];
    [myOptionsButton release];
    [myOptionsDoneButton release];
    [mySpinnerView release];
    [super dealloc];
}

- (void)loadView 
{
    [super loadView];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor kCellBackgroundColor];
    self.tableView.separatorColor = [UIColor whiteColor];
    self.tableView.rowHeight = 36;

    myBrowseRoot.selectedSegmentIndex = theHostPrefs.browseHomeDir ? 0 : 1;
    
    [self hideOptionsAnimated:NO];
    
    CGRect frame = myOptionView.frame;
    frame.origin.y = -frame.size.height;
    myOptionView.frame = frame;
    myTableView.contentOffset = CGPointZero;
    myTableView.contentInset = UIEdgeInsetsZero;
}

- (void)showSpinner
{
    mySpinnerView.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!myDirectoryEntries)
	[self performSelector:@selector(showSpinner) withObject:nil afterDelay:kSpinnerDelay];
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

- (void)showOptionsAnimated:(BOOL)animated
{
    if (self.navigationItem.rightBarButtonItem == myOptionsDoneButton) return;
    
    [self.navigationItem setRightBarButtonItem:myOptionsDoneButton animated:animated];
    
    // Update the UI values
    myHiddenSwitch.on = theHostPrefs.showHiddenFiles;
    myBrowseRoot.selectedSegmentIndex = theHostPrefs.browseHomeDir ? 0 : 1;
    
    myOptionView.hidden = NO;
    
    // Show the options UI elements
    if (animated)
	[UIView beginAnimations:@"Directory Options" context:nil];
    
    CGRect frame = myOptionView.frame;
    frame.origin.y = 0;
    myOptionView.frame = frame;
    
    CGPoint content_offset = myTableView.contentOffset;
    content_offset.y -= frame.size.height;
    myTableView.contentOffset = content_offset;
    
    if (animated)
	[UIView commitAnimations];
    
    UIEdgeInsets insets = myTableView.contentInset;
    insets.top = frame.size.height;
    myTableView.contentInset = insets;
    
    insets = myTableView.scrollIndicatorInsets;
    insets.top = frame.size.height;
    myTableView.scrollIndicatorInsets = insets;
}

- (void)hideOptionsAnimated:(BOOL)animated
{
    if (!myOptionView) return;
    
    if (self.navigationItem.rightBarButtonItem == myOptionsButton) return;
    
    // Check if the browse root has changed
    BOOL browse_home = myBrowseRoot.selectedSegmentIndex == 0;
    if (browse_home != theHostPrefs.browseHomeDir)
    {
	theHostPrefs.browseHomeDir = browse_home;
	RemoteFileBrowserController * shared_controller;
	shared_controller = [RemoteFileBrowserController sharedController];
	[shared_controller resetToRoot];
    }
    
    [self.navigationItem setRightBarButtonItem:myOptionsButton animated:animated];
    
    if (animated)
	[UIView beginAnimations:@"Directory Options" context:nil];
    else
	myOptionView.hidden = YES;
        
    CGRect frame = myOptionView.frame;
    frame.origin.y = -frame.size.height;
    myOptionView.frame = frame;
    
    CGPoint content_offset = myTableView.contentOffset;
    content_offset.y += frame.size.height;
    myTableView.contentOffset = content_offset;
    
    if (animated)
	[UIView commitAnimations];
    
    UIEdgeInsets insets = myTableView.contentInset;
    insets.top = 0.0;
    myTableView.contentInset = insets;
    
    insets = myTableView.scrollIndicatorInsets;
    insets.top = 0.0;
    myTableView.scrollIndicatorInsets = insets;
}

- (void)showOptions
{
    [self showOptionsAnimated:YES];
}

- (void)hideOptions
{
    [self hideOptionsAnimated:YES];
}

- (IBAction)showHiddenChanged:(id)sender
{
    UISwitch * switch_control = (UISwitch*)sender;
    
    if (theHostPrefs)
	theHostPrefs.showHiddenFiles = switch_control.on;
        
    [myTableView reloadData];
}

- (void)downloadFinished:(NSNotification*)notification
{
    NetworkOperation * op = [notification object];
    NSArray * keys = [theActiveDownloads allKeysForObject:op];
    [theActiveDownloads removeObjectsForKeys:keys];
    [myTableView reloadData];
}

- (void)reset
{
    self.directoryEntries = nil;
    [self hideOptionsAnimated:NO];
}

- (void)_addSpinnerToCell:(NSIndexPath*)index_path white:(BOOL)white;
{
    UITableViewCell * cell = [myTableView cellForRowAtIndexPath:index_path];
    if (cell)
    {
	UIActivityIndicatorView * spinner;
	spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	if (white)
	    spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
	cell.accessoryView = spinner;
	[spinner startAnimating];
	[spinner release];	    	    
    }
}

#pragma mark UITableViewDelegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    NSInteger result = 0;
    
    if (self.directoryEntries)
    {
	result = [self.directoryEntries count];
#if ! BRIEFCASE_LITE
	result += 1;
#endif
    }
    
    return result;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index_path
{
    [self hideOptionsAnimated:YES];
    
    RemoteFileBrowserController * shared_controller = [RemoteFileBrowserController sharedController];
    DownloadController * download_controller = [DownloadController sharedController];
    
    NSInteger index = index_path.row;
    
#if ! BRIEFCASE_LITE
    index -= 1;

    if (index_path.row == 0)
    {
	// Download directory
	NetworkOperation * op = [download_controller downloadDirectory:myPath];
	if (op)
	{
	    [theActiveDownloads setObject:op forKey:myPath];
	    
	    [self _addSpinnerToCell:index_path white:YES];
	}
	
	return;
    }
#endif
    
    SFTPFileAttributes * file = [self.directoryEntries objectAtIndex:index];

    if ([file isDir])
    {
	if  ([Utilities isBundle:file.name])
	{
	    NSString * new_path = [myPath stringByAppendingPathComponent:file.name];
	    NetworkOperation * op = [download_controller zipAndDownloadDirectory:new_path];
	    if (op)
	    {
		NSString * file_path = [myPath stringByAppendingPathComponent:file.name];
		[theActiveDownloads setObject:op forKey:file_path];
		[self _addSpinnerToCell:index_path  white:NO];
	    }
	}
	else
	{
	    NSString * new_path = [myPath stringByAppendingPathComponent:file.name];
	    [shared_controller pushViewForPath:new_path];
	}
    }
    else 
    {
	// Download the file
	NSString * new_path = [myPath stringByAppendingPathComponent:file.name];
	
	NetworkOperation * op = [download_controller downloadFile:new_path ofSize:file.size];
	
	if (op)
	{
	    NSString * file_path = [myPath stringByAppendingPathComponent:file.name];
	    [theActiveDownloads setObject:op forKey:file_path];
	    
	    [self _addSpinnerToCell:index_path white:NO];
	}
	
	[myTableView deselectRowAtIndexPath:index_path animated:YES];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)index_path
{
    NSString * file_path;
    
    NSInteger index = index_path.row;
    
#if ! BRIEFCASE_LITE
    // Account for directory download item
    index -= 1;
    
    if (index_path.row == 0)
	file_path = myPath;
    else
#endif
    {
	SFTPFileAttributes * file_attributes = [self.directoryEntries objectAtIndex:index];
	file_path = [myPath stringByAppendingPathComponent:file_attributes.name];
    }
    
    if ([theActiveDownloads objectForKey:file_path])
	// Don't allow selection of an item that is downloading
	return nil;
    
    return index_path;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)index_path 
{    
    UITableViewCell * cell;
    
    NSInteger index = index_path.row;
    
#if ! BRIEFCASE_LITE
    // Account for directory download item
    index -= 1;
    
    if (index_path.row == 0)
    {
	cell = [tableView dequeueReusableCellWithIdentifier:kDownloadDirectoryCell];
	if (cell == nil)
	    cell = [[[DirectoryDownloadCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDownloadDirectoryCell] autorelease];
	
	if ([theActiveDownloads objectForKey:myPath])
	{
	    // This directory has an active download in progress
	    UIActivityIndicatorView * spinner;
	    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	    cell.accessoryView = spinner;
	    [spinner startAnimating];
	    [spinner release];	    
	}
	else
	    cell.accessoryView = nil;
    }
    else
#endif	
    {
	cell = [tableView dequeueReusableCellWithIdentifier:kDirectoryCell];
	if (cell == nil)
	{
	    cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDirectoryCell] autorelease];
	    cell.font = [UIFont boldSystemFontOfSize:16.0];
	    cell.lineBreakMode = UILineBreakModeMiddleTruncation;
	}
	else
	    cell.accessoryView = nil;
	
	SFTPFileAttributes * file_attributes = [self.directoryEntries objectAtIndex:index];
	cell.text = file_attributes.name;
	if (file_attributes.isDir && ![Utilities isBundle:file_attributes.name])
	{
	    cell.accessoryView = nil;
	    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	    cell.image = [IconManager iconForFolderSmall:YES];
	}
	else
	{
	    NSString * file_path = [myPath stringByAppendingPathComponent:file_attributes.name];
	    if ([theActiveDownloads objectForKey:file_path])
	    {
		// This cell has an active download in progress
		UIActivityIndicatorView * spinner;
		spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		cell.accessoryView = spinner;
		[spinner startAnimating];
		[spinner release];	    
	    }
	    else
	    {
		cell.accessoryType = UITableViewCellAccessoryNone;
		if (!file_attributes.isDir)
		{
		    UILabel * size_label = [[UILabel alloc] init];
		    size_label.text = [Utilities humanReadibleMemoryDescription:file_attributes.size];
		    size_label.backgroundColor = myTableView.backgroundColor;
		    size_label.textColor = [UIColor colorWithWhite:0.28 alpha:1.0];
		    size_label.font = [UIFont systemFontOfSize:12];
		    [size_label sizeToFit];
		    cell.accessoryView = size_label;
		}
	    }
	    
	    NSString * extension = [[file_attributes.name pathExtension] lowercaseString];
	    cell.image = [IconManager iconForExtension:extension smallIcon:YES];
	}
    }
    
    // Configure the cell
    return cell;
}

#pragma mark Properties

- (NSArray*)directoryEntries
{
    if (theHostPrefs.showHiddenFiles)
	return myDirectoryEntries;
    else
	return myFilteredDirectoryEntries;
}

- (void)setDirectoryEntries: (NSArray*)directories
{
    [myDirectoryEntries release];
    [myFilteredDirectoryEntries release];

    if (directories)
    {
	// Don't show the spinner
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	mySpinnerView.hidden = YES;
	
	myDirectoryEntries = [directories retain];
	myFilteredDirectoryEntries = [RemoteBrowserUtilities filterFileList:myDirectoryEntries 
								 remotePath:myPath 
								 showHidden:NO 
								  showFiles:YES];
    }
    else
    {
	myDirectoryEntries = nil;
	myFilteredDirectoryEntries = nil;
    }
    [self.tableView reloadData];
}

- (void)setPath:(NSString*)path
{
    myPath = [path retain];
    
    if ([myPath compare:@"/"] == NSOrderedSame)
	self.navigationItem.title = @"/";
    else
	self.navigationItem.title = [path lastPathComponent];
}


@end

