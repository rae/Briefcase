//
//  FileActionController.m
//  Briefcase
//
//  Created by Michael Taylor on 20/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "FileActionController.h"
#import "File.h"
#import "FileType.h"
#import "FileAction.h"
#import "Connection.h"
#import "ConnectionController.h"
#import "FileInfoCell.h"
#import "NetworkOperation.h"
#import "NetworkOperationQueue.h"
#import "HostPrefs.h"
#import "ChooseLocationController.h"
#import "CustomLocationAction.h"
#import "FileActionCell.h"
#import "SystemInformation.h"
#import "ConnectForOptionsCell.h"
#import "BriefcaseAppDelegate.h"

#import "MovieType.h"
#import "AudioType.h"
#import "ImageType.h"
#import "DocumentType.h"
#import "DiskImageType.h"
#import "MacApplicationType.h"
#import "InstallerPackageType.h"
#import "SourceCodeType.h"

static NSString * kBasicActionCell = @"kBasicActionCell";

#define FLOATRGBA(A,B,C) colorWithRed:((CGFloat)A/255.0) green:((CGFloat)B/255.0) blue:((CGFloat)C/255.0) alpha:1.0

// View Gradient
#define kBackgroundColor		FLOATRGBA(182, 186, 219)

@implementation FileActionController

- (id)init 
{
    if (self = [super initWithNibName:nil bundle:nil]) 
    {
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(connectionEstablished:) 
		       name:kMainConnectionEstablished 
		     object:nil];
	[center addObserver:self 
		   selector:@selector(connectionTerminated:) 
		       name:kMainConnectionTerminated
		     object:nil];
	[center addObserver:self 
		   selector:@selector(attributeAdded:)
		       name:kFileAttributeAdded 
		     object:nil];
	
	myConnection = nil;
	
	myInProgressIdentifiers = [[NSMutableSet alloc] init];
	
	myFileInfoCell = [[FileInfoCell alloc] initWithFrame:CGRectZero];
	myConnectForInfoCell = [[ConnectForOptionsCell alloc] initWithFrame:CGRectZero];
	
	// Initialize the file types
	[[[FileType alloc] initWithWeight:1] release];
	[[[MovieType alloc] init] release];
	[[[AudioType alloc] init] release];
	[[[ImageType alloc] init] release];
	[[[DocumentType alloc] init] release];
	[[[DiskImageType alloc] init] release];
	
#if ! BRIEFCASE_LITE
	[[[MacApplicationType alloc] init] release];
	[[[InstallerPackageType alloc] init] release];
	[[[SourceCodeType alloc] init] release];
#endif
    }
    return self;
}

- (void)loadView 
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    myTableView = [UITableView alloc];
    [myTableView initWithFrame:frame style:UITableViewStyleGrouped];
    myTableView.backgroundColor = [UIColor kBackgroundColor];
    
    myTableView.delegate = self;
    myTableView.dataSource = self;	
    myTableView.allowsSelectionDuringEditing = YES;
    self.view = myTableView;
}

- (void)attributeAdded:(NSNotification*)notification
{
    NSArray * item = [notification object];
    myFileInfoCell.attributes = [myFileInfoCell.attributes arrayByAddingObject:item];
    [myTableView reloadData];
}

- (void)dealloc 
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
    
    [myFile release];
    [myFileType release];
    [myFileSpecificActions release];
    [myConnectForInfoCell release];
    [myFileInfoCell release];
    [super dealloc];
}

- (NSArray*)_filterOutMacActions:(NSArray*)actions
{
    NSMutableArray * result = [NSMutableArray array];
    for (FileAction * action in actions)
    {
	if (!action.requiresMac)
	    [result addObject:action];
    }
    return result;
}

- (void)_filterActionsForConnection:(Connection *)connection
{
    SystemInformation * system_info = (SystemInformation*)connection.userData;
    if (system_info && !system_info.isConnectedToMac)
    {
	myFixedUploadActions = [[self _filterOutMacActions:myFixedUploadActions] retain];
	myFileSpecificActions = [[self _filterOutMacActions:myFileSpecificActions] retain];
    }
}

- (void)_updateFileActions
{
    ConnectionController * controller = [ConnectionController sharedController];
    myIsBriefcaseConnection = controller.isInterBriefcaseConnection;
    
    if (myIsBriefcaseConnection)
    {
	myFixedUploadActions = [[myFileType getBriefcaseActions] retain];
	myFileSpecificActions = nil;
    }
    else
    {
	myFixedUploadActions = [[myFileType getUploadActions] retain];
	myFileSpecificActions = [[myFileType getFileSpecificActions] retain];
	
	[self _filterActionsForConnection:myConnection];
    }    
}

- (void)_systemInfoReceived:(NSNotification*)notification
{
    if (myConnection.userData)
    {
	[self _updateFileActions];
	[myTableView reloadData];
    }
}

- (void)connectionEstablished:(NSNotification*)notification
{
    ConnectionController * controller = [ConnectionController sharedController];
    myConnection = [controller.currentConnection retain];
    myIsBriefcaseConnection = controller.isInterBriefcaseConnection;
    
    [self _updateFileActions];  
    
    // Watch for load of system information
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self 
	       selector:@selector(_systemInfoReceived:) 
		   name:kSystemInfoChanged 
		 object:nil];
    
    if (myIsBriefcaseConnection)
    {
	[myCustomUploadActions release];
	myCustomUploadActions = nil;
    }
    else
    {
	NSAssert(myCustomUploadActions==nil,@"Should not be custom connections");
	HostPrefs * host_prefs = [HostPrefs hostPrefsWithHostname:myConnection.hostName];
	
	NSArray * locations = host_prefs.uploadLocations;
	myCustomUploadActions = [[NSMutableArray alloc] initWithCapacity:[locations count]];
	CustomLocationAction * action;
	for (NSString * location in locations)
	{
	    action = [[CustomLocationAction alloc] initWithCustomLocation:location];
	    [myCustomUploadActions addObject:action];
	    [action release];
	}
	
	// Add edit button if we are connected to a computer
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
    
    [myTableView reloadData];
}

- (void)connectionTerminated:(NSNotification*)notification
{
    [myCustomUploadActions release];
    myCustomUploadActions = nil;
    [myConnection release];
    myConnection = nil;
    [myTableView reloadData];
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:kSystemInfoChanged object:nil];
    
    // No Edit button unless we are connected
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)_opFinished:(NSNotification*)notification
{
    // Track the completion of a job we started to update our UI
    NetworkOperation * op = [notification object];
    NSString * ident = op.jobIdentifier;
    [myInProgressIdentifiers removeObject:ident];
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:kNetworkOperationEnd object:op];
    
    if (![myInProgressIdentifiers containsObject:op.jobIdentifier])
	// This was the last operation for the job, update the view
	[myTableView reloadData];
}

- (void)launchAction:(FileAction*)action
{
    // First get a unique identifier for this operation performed on 
    // the current file, so that we can monitor whether the operation is done
    NSString * identifier = [action identifierForFile:myFile];
    
    // Start the operations going
    NSArray * operations = [action queueOperationsForFile:myFile connection:myConnection];
    
    if (!operations) 
	return;
    
    // Set up to monitor for their completion
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    for (NetworkOperation * op in operations)
    {
	[myInProgressIdentifiers addObject:identifier];
	op.jobIdentifier = identifier;
	[center addObserver:self
		   selector:@selector(_opFinished:) 
		       name:kNetworkOperationEnd
		     object:op];
	[center addObserver:self
		   selector:@selector(_opFinished:) 
		       name:kNetworkOperationCancelled
		     object:op];
    }
    
    [myTableView reloadData];
}

- (void)_updateHostPrefs
{
    HostPrefs * host_prefs = [HostPrefs hostPrefsWithHostname:myConnection.hostName];
    
    if (!host_prefs)
	return;
    
    NSMutableArray * locations = [NSMutableArray arrayWithCapacity:[myCustomUploadActions count]];
    
    for (CustomLocationAction * action in myCustomUploadActions)
	[locations addObject:action.location];
    
    host_prefs.uploadLocations = locations;
    [host_prefs save];
}

- (void)chooseLocationAndUpload
{
    UINavigationController * parent = (UINavigationController*)self.parentViewController;
    [ChooseLocationController chooseLocationWithNavigationController:parent 
							      target:self 
							    selector:@selector(_chooseLocationDone:)];
}

- (void)_chooseLocationDone:(NSString*)path
{
    NSArray * operations;
    @try 
    {
	// Gather the operations for this action
	operations = [FileAction operationsForUploadOfFile:myFile toPath:path];
	
	for (NSOperation * op in operations)
	    [[NetworkOperationQueue sharedQueue] addOperation:op];
    }
    @catch (NSException * e) 
    {
	UIAlertView *alert = 
	alert = [[UIAlertView alloc] initWithTitle:[e name] 
					   message:[e reason]
					  delegate:nil 
				 cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
				 otherButtonTitles:nil];
	[alert show];	
	[alert release];
	
	operations = nil;
    }
}

- (void)editLocationAtIndex:(NSInteger)index
{
    myCustomUploadEditIndex = index;
    UINavigationController * parent = (UINavigationController*)self.parentViewController;
    [ChooseLocationController chooseLocationWithNavigationController:parent 
							      target:self 
							    selector:@selector(_editLocationDone:)];
}

- (void)_editLocationDone:(NSString*)path
{
    if (myCustomUploadEditIndex >= [myCustomUploadActions count])
	[myCustomUploadActions addObject:[[CustomLocationAction alloc] initWithCustomLocation:path]];
    else
    {
	CustomLocationAction * action = [myCustomUploadActions objectAtIndex:myCustomUploadEditIndex];
	action.location = path;
    }
    
    [myTableView reloadData];
        
    [self _updateHostPrefs];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated 
{
    [super setEditing:editing animated:animated];
    
    [myTableView setEditing:editing animated:YES];
    
    // Figure out where the remote path placeholder goes
    NSInteger index = [myFixedUploadActions count] + [myCustomUploadActions count];
    NSIndexPath * index_path = [NSIndexPath indexPathForRow:index inSection:1];
    
    if (editing)
	[myTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:index_path] 
			   withRowAnimation:UITableViewRowAnimationFade];
    else
	[myTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:index_path] 
			   withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    if (myConnection)
    {
	if (myFileSpecificActions && [myFileSpecificActions count] > 0)
	    return 3;
	else
	    return 2;
    }
    else
    {
	return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    switch (section) 
    {
	case 0:
	    // Information section
	    return 1;
	    break;
	case 1:
	{
	    if (myConnection)
	    {
		// Upload section
		NSInteger count = [myFixedUploadActions count];
		if (!myIsBriefcaseConnection)
		{
		    count += [myCustomUploadActions count];
		    count ++;
		    if (myTableView.editing)
			count++;
		}
		return count;
	    }
	    else
	    {
		// Show the message about needing to connect
		return 1;
	    }
	    break;
	    
	}
	case 2:
	    // File specific section
	    return [myFileSpecificActions count];
	    break;
	default:
	    break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)index_path 
{
    FileAction * action = nil;
    
    if (index_path.section == 0)
	return myFileInfoCell;
    else if (index_path.section == 1 && !myConnection)
	return myConnectForInfoCell;
    
    FileActionCell * cell = (FileActionCell*)[myTableView dequeueReusableCellWithIdentifier:kBasicActionCell];
    if (cell == nil) {
	cell = [[[FileActionCell alloc] initWithFrame:CGRectZero reuseIdentifier:kBasicActionCell] autorelease];
	cell.textAlignment = UITextAlignmentCenter;
    }
    else
    {
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.accessoryView = nil;
	cell.textColor = [UIColor blackColor];
	cell.hidesAccessoryWhenEditing = YES;
    }
    
    switch (index_path.section) 
    {	    
	case 1:
	{
	    NSInteger add_index = -1;
	    NSInteger count = [myFixedUploadActions count] + [myCustomUploadActions count];
	    NSInteger choose_index = count;
	    if (myTableView.editing)
	    {
		add_index = choose_index;
		choose_index++;
	    }
	    
	    if (index_path.row >= [myFixedUploadActions count] && index_path.row < count)
		cell.showDisclosureAccessoryWhenEditing = YES;
	    else
		cell.showDisclosureAccessoryWhenEditing = NO;

	    if (index_path.row == add_index)
	    {
		cell.textColor = [UIColor darkGrayColor];
		cell.text = NSLocalizedString(@"Add New Destination",@"Title for button that allows the user to add a new remote destination to upload files to");
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.hidesAccessoryWhenEditing = NO;
		return cell;
	    }
	    if (index_path.row == choose_index)
	    {
		// Special case.  The user needs to choose a location
		cell.text = NSLocalizedString(@"Choose Destination", @"Button allowing the user to choose a destination for their file on the remote machine");
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	    }
	    
	    if (index_path.row < [myFixedUploadActions count])
		action = [myFixedUploadActions objectAtIndex:index_path.row];
	    else
		action = [myCustomUploadActions objectAtIndex:(index_path.row - [myFixedUploadActions count])];
	    break;
	}
	case 2:
	    action = [myFileSpecificActions objectAtIndex:index_path.row];
	    break;
	default:
	    return nil;
    }
    
    
    NSString * identifier = [action identifierForFile:myFile];
    if ([myInProgressIdentifiers containsObject:identifier])
    {
	cell.showSpinner;
    }
    else
	cell.accessoryType = action.accessoryType;
    
    cell.text = action.title;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)index_path
{
    if (index_path.section == 0)
	return myFileInfoCell.preferredHeight;
    else
	return 40.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) 
    {
	case 1:
	    if (myConnection)
		return NSLocalizedString(@"Upload to:", @"Title for table section that lists places you can upload your file to");
	    break;
	case 2:
	    return NSLocalizedString(@"Available Actions", @"Actions available to the user for this file");
	    break;
	default:
	    break;
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)index_path
{
    if (index_path.section != 1)
	return NO;
    
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)index_path
{
    NSAssert(index_path.section == 1, @"Invalid section");
    
    NSInteger index = index_path.row - [myFixedUploadActions count];
    NSAssert(index >= 0,@"Invalid index");
    
    if (index < [myCustomUploadActions count])
    {
	NSAssert(editingStyle == UITableViewCellEditingStyleDelete,@"Mismatched editing style");
	[myCustomUploadActions removeObjectAtIndex:index];
	[self _updateHostPrefs];
	[myTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:index_path] withRowAnimation:YES];
    }
    else
    {
	NSAssert(editingStyle == UITableViewCellEditingStyleInsert,@"Mismatched editing style");
	[self editLocationAtIndex:index];
	return;
    }
}

#pragma mark UITableViewDelegate methods

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)index_path
{
    NSInteger count = [myFixedUploadActions count] + [myCustomUploadActions count];

    // Edit mode
    if (myTableView.editing)
    {
	if (index_path.section != 1 || index_path.row < [myFixedUploadActions count])
	    return nil;
	else if (index_path.row == count + 2)
	    return nil;
	else
	    return index_path;
    }
    
    // Choose button
    if (index_path.section == 1 && index_path.row >= count)
    {
	if (myTableView.editing)
	    return nil;
	else
	    return index_path;
    }
    
    // Find the file action
    FileAction * action = nil;
    
    switch (index_path.section) 
    {	    
	case 0:
	    return nil;
	case 1:
	{
	    if (index_path.row < [myFixedUploadActions count])
		action = [myFixedUploadActions objectAtIndex:index_path.row];
	    else 
		action = [myCustomUploadActions objectAtIndex:(index_path.row - [myFixedUploadActions count])];
	    break;
	}
	case 2:
	    action = [myFileSpecificActions objectAtIndex:index_path.row];
	    break;
	default:
	    return nil;
    }
    
    // Check if this operation is in progress
    NSString * identifier = [action identifierForFile:myFile];
    
    if ([myInProgressIdentifiers containsObject:identifier])
	return nil;
    else
	return index_path;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index_path 
{
    [myTableView deselectRowAtIndexPath:index_path animated:YES];
 
    if (!myConnection && index_path.section == 1 && index_path.row == 0)
    {
	// Connect for more information cell
	[[BriefcaseAppDelegate sharedAppDelegate] gotoConnectTab];
	return;
    }
    
    // Edit mode
    if (myTableView.editing)
    {
	NSAssert(index_path.section == 1, @"Wrong section");
	
	NSInteger index = index_path.row - [myFixedUploadActions count];
	NSAssert(index>=0,@"Invalid index");
	
	[self editLocationAtIndex:index];
	return;
    }
    
    // Choose button    
    NSInteger count = [myFixedUploadActions count] + [myCustomUploadActions count];
    if (index_path.section == 1 && index_path.row >= count)
    {
	[self chooseLocationAndUpload];
	return;
    }
    
    FileAction * action = nil;
    
    switch (index_path.section) 
    {	    
	case 0:
	    return;
	case 1:
	    if (index_path.row < [myFixedUploadActions count])
		action = [myFixedUploadActions objectAtIndex:index_path.row];
	    else 
		action = [myCustomUploadActions objectAtIndex:(index_path.row - [myFixedUploadActions count])];
	    break;
	case 2:
	    action = [myFileSpecificActions objectAtIndex:index_path.row];
	    break;
	default:
	    return;
    }
    
    [self launchAction:action];
    
    // Deselect the cell again
    [myTableView deselectRowAtIndexPath:index_path animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)index_path
{
    if (self.editing == NO || !index_path || index_path.section != 1)
	return UITableViewCellEditingStyleNone;
    
    if (index_path.row < [myFixedUploadActions count])
	return UITableViewCellEditingStyleNone;
    
    if (index_path.row < [myFixedUploadActions count] + [myCustomUploadActions count])
	return UITableViewCellEditingStyleDelete;
    
    if (myTableView.editing && index_path.row == [myFixedUploadActions count] + [myCustomUploadActions count])
	return UITableViewCellEditingStyleInsert;
    
    return UITableViewCellEditingStyleNone;
}

#pragma mark Properties

- (File*)file
{
    return myFile;
}

- (void)setFile:(File*)file
{
    [myFile release];
    [myFileType release];
    [myFixedUploadActions release];
    [myFileSpecificActions release];
    
    myFile = [file retain];
    myFileType = [[FileType findBestMatch:file] retain];
    
    if (myIsBriefcaseConnection)
    {
	myFixedUploadActions = [[myFileType getBriefcaseActions] retain];
	myFileSpecificActions = nil;
    }
    else
    {
	myFixedUploadActions = [[myFileType getUploadActions] retain];
	myFileSpecificActions = [[myFileType getFileSpecificActions] retain];
	
	[self _filterActionsForConnection:myConnection];
    }    
    
    myFileInfoCell.attributes = [myFileType getAttributesForFile:file];
    
    myFileInfoCell.icon = [myFileType getPreviewForFile:file];
    
    [myTableView reloadData];
    
    self.navigationItem.title = [file.path lastPathComponent];
}

@end
