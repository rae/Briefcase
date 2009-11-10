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
#import "BCConnection.h"
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
#import "SectionedTable.h"
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

static NSString * kInformationSection = @"information";
static NSString * kEmailSection = @"email";
static NSString * kUploadSection = @"upload";
static NSString * kBriefcaseUploadSection = @"briefcase upload";
static NSString * kActionSection = @"actions";
static NSString * kNeedConnectSection = @"need connect";

@interface FileActionController (Private)

- (void)updateActiveSectionList;

@end


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
    myTableView = [[SectionedTable alloc] initWithFrame:frame];
    myTableView.backgroundColor = [UIColor kBackgroundColor];
    
    myTableView.allowsSelectionDuringEditing = YES;
    self.view = myTableView;
    
    // Add Table Sections
    [myTableView addSection:self withID:kInformationSection];
#if ! BRIEFCASE_LITE
    [myTableView addSection:self withID:kEmailSection];
#endif
    [myTableView addSection:self withID:kUploadSection];
    [myTableView addSection:self withID:kBriefcaseUploadSection];
    [myTableView addSection:self withID:kNeedConnectSection];
    [myTableView addSection:self withID:kActionSection];
    
    [self updateActiveSectionList];
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

- (void)_filterActionsForConnection:(BCConnection *)connection
{
    SystemInformation * system_info = (SystemInformation*)connection.userData;
    if (system_info && !system_info.isConnectedToMac)
    {
	myFixedUploadActions = [[self _filterOutMacActions:myFixedUploadActions] retain];
	NSLog(@"Prefilter: %d", [myFileSpecificActions count]);
	myFileSpecificActions = [[self _filterOutMacActions:myFileSpecificActions] retain];
	NSLog(@"Postfilter: %d", [myFileSpecificActions count]);
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
    
    [self updateActiveSectionList];
    
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
    
    // Set up table sections for no connection
    [self updateActiveSectionList];
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

#pragma mark Email Support

- (void)emailFile
{
    
#if ! BRIEFCASE_LITE
    if ([MFMailComposeViewController canSendMail])
    {
	MFMailComposeViewController * mail_controller = [[MFMailComposeViewController alloc] init];
	mail_controller.mailComposeDelegate = self;
	
	NSData * attachment_data = [NSData dataWithContentsOfFile:myFile.path];
	[mail_controller addAttachmentData:attachment_data
				  mimeType:myFile.mimeType 
				  fileName:myFile.fileName];
	
	[mail_controller setSubject:myFile.fileName];
	
	
//	UIDevice * device = [UIDevice currentDevice];
//	NSString * format = NSLocalizedString(@"Sent from Briefcase on my %@", @"Default message body for emails sent from Briefcase. The name of the device (eg iPhone) is substituted in");
//	NSString * message = [NSString stringWithFormat:format, device.model];
	[mail_controller setMessageBody:[NSString string] isHTML:NO];
	
	[self presentModalViewController:mail_controller animated:YES];
    }
    else 
    {
        UIAlertView * email_alert;
        NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Your %@ is not configured to send email",@"Message when trying to send email attachment from device with no email accounts set up"),
                              [UIDevice currentDevice].model];
        email_alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email Error",@"Title when cannot send email") 
                                                 message:message
                                                delegate:self 
                                       cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
                                       otherButtonTitles:nil];
        [email_alert show];
    }
#endif
}

#if ! BRIEFCASE_LITE
- (void)mailComposeController:(MFMailComposeViewController*)controller 
	  didFinishWithResult:(MFMailComposeResult)result 
			error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
}
#endif


#pragma mark TableSection methods

- (NSInteger)sectionedTable:(SectionedTable*)table numberOfRowsInSection:(NSString*)section_id;
{
    if ([section_id isEqual:kUploadSection])
    {
	NSInteger count = [myFixedUploadActions count];

	count += [myCustomUploadActions count];
	count ++;
	if (myTableView.editing)
	    count++;
	
	return count;
    }
    else if ([section_id isEqual:kBriefcaseUploadSection])
	return [myFixedUploadActions count];
    else if ([section_id isEqual:kActionSection])
    {
	NSLog(@"ST Action Count: %d", [myFileSpecificActions count]);
	return [myFileSpecificActions count];
    }
    else
	// Information, email, or needs connection sections
	return 1;
}
- (UITableViewCell*)sectionedTable:(SectionedTable*)table cellInSection:(NSString*)section_id forRow:(NSUInteger)row;
{
    FileAction * action = nil;
    
    if ([section_id isEqual:kInformationSection])
	return myFileInfoCell;
    else if ([section_id isEqual:kNeedConnectSection])
	return myConnectForInfoCell;
    
    FileActionCell * cell = (FileActionCell*)[myTableView dequeueReusableCellWithIdentifier:kBasicActionCell];
    if (cell == nil) {
	cell = [[[FileActionCell alloc] initWithFrame:CGRectZero reuseIdentifier:kBasicActionCell] autorelease];
	cell.textLabel.textAlignment = UITextAlignmentCenter;
    }
    else
    {
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.accessoryView = nil;
	cell.textLabel.textColor = [UIColor blackColor];
	cell.hidesAccessoryWhenEditing = YES;
    }
    
    if ([section_id isEqual:kEmailSection])
    {
	cell.textLabel.text = NSLocalizedString(@"Email File", @"Label for button that allows the sending of e-mail");
	return cell;
    }
    else if ([section_id isEqual:kUploadSection])
    {
	NSInteger add_index = -1;
	NSInteger count = [myFixedUploadActions count] + [myCustomUploadActions count];
	NSInteger choose_index = count;
	if (myTableView.editing)
	{
	    add_index = choose_index;
	    choose_index++;
	}
	
	if (row >= [myFixedUploadActions count] && row < count)
	    cell.showDisclosureAccessoryWhenEditing = YES;
	else
	    cell.showDisclosureAccessoryWhenEditing = NO;
	
	if (row == add_index)
	{
	    cell.textLabel.textColor = [UIColor darkGrayColor];
	    cell.textLabel.text = NSLocalizedString(@"Add New Destination",@"Title for button that allows the user to add a new remote destination to upload files to");
	    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	    cell.hidesAccessoryWhenEditing = NO;
	    return cell;
	}
	if (row == choose_index)
	{
	    // Special case.  The user needs to choose a location
	    cell.textLabel.text = NSLocalizedString(@"Choose Destination", @"Button allowing the user to choose a destination for their file on the remote machine");
	    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	    return cell;
	}
	
	if (row < [myFixedUploadActions count])
	    action = [myFixedUploadActions objectAtIndex:row];
	else
	    action = [myCustomUploadActions objectAtIndex:(row - [myFixedUploadActions count])];
    }
    else if ([section_id isEqual:kBriefcaseUploadSection])
        action = [myFixedUploadActions objectAtIndex:row];
    else if ([section_id isEqual:kActionSection])
	action = [myFileSpecificActions objectAtIndex:row];

    NSString * identifier = [action identifierForFile:myFile];
    if ([myInProgressIdentifiers containsObject:identifier])
    {
	cell.showSpinner;
    }
    else
	cell.accessoryType = action.accessoryType;
    
    cell.textLabel.text = action.title;
    
    return cell;
}

- (CGFloat)sectionedTable:(SectionedTable*)table heightInSection:(NSString*)section_id forRow:(NSUInteger)row
{
    if ([section_id isEqual:kInformationSection])
	return myFileInfoCell.preferredHeight;
    else
	return 40.0;
}

- (NSString*)sectionedTable:(SectionedTable*)table titleForSection:(NSString*)section_id
{
    if ([section_id isEqual:kUploadSection] || [section_id isEqual:kBriefcaseUploadSection])
	return NSLocalizedString(@"Upload to:", @"Title for table section that lists places you can upload your file to");
    else if ([section_id isEqual:kActionSection])
	return NSLocalizedString(@"Available Actions", @"Actions available to the user for this file");
    
    return nil;
}

- (BOOL)sectionedTable:(SectionedTable*)table canEditInSection:(NSString*)section_id forRow:(NSUInteger)row
{
    if ([section_id isEqual:kUploadSection])
	return YES;
    else
	return NO;
}

- (void)sectionedTable:(SectionedTable*)table section:(NSString*)section_id commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRow:(NSUInteger)row
{
    NSAssert([section_id isEqual:kUploadSection], @"Invalid section");
    
    NSInteger index = row - [myFixedUploadActions count];
    NSAssert(index >= 0,@"Invalid index");
    
    if (index < [myCustomUploadActions count])
    {
	NSAssert(editingStyle == UITableViewCellEditingStyleDelete,@"Mismatched editing style");
	[myCustomUploadActions removeObjectAtIndex:index];
	[self _updateHostPrefs];
	[myTableView deleteRow:index inSection:section_id withRowAnimation:UITableViewRowAnimationLeft];
    }
    else
    {
	NSAssert(editingStyle == UITableViewCellEditingStyleInsert,@"Mismatched editing style");
	[self editLocationAtIndex:index];
	return;
    }
    
}

#pragma mark UITableViewDelegate methods

- (BOOL)sectionedTable:(SectionedTable*)table section:(NSString*)section_id canSelectRow:(NSUInteger)row
{
    if ([section_id isEqual:kInformationSection])
	return NO;
    
    if (myTableView.editing)
    {
	if ([section_id isEqual:kUploadSection] && row >= [myFixedUploadActions count])
	    return YES;
	else
	    return NO;
    }
    
    // Find the file action
    FileAction * action = nil;
    
    if ([section_id isEqual:kEmailSection] || [section_id isEqual:kNeedConnectSection])
	return YES;
    else if ([section_id isEqual:kUploadSection] || [section_id isEqual:kBriefcaseUploadSection])
    {
	if (row < [myFixedUploadActions count])
	    action = [myFixedUploadActions objectAtIndex:row];
	else if (row >= [myFixedUploadActions count] + [myCustomUploadActions count])
	    return YES;
	else 
	    action = [myCustomUploadActions objectAtIndex:(row - [myFixedUploadActions count])];	
    }
    else if ([section_id isEqual:kActionSection])
	action = [myFileSpecificActions objectAtIndex:row];
    else
	return NO;
    
    // Check if this operation is in progress
    NSString * identifier = [action identifierForFile:myFile];
    
    return ![myInProgressIdentifiers containsObject:identifier];    
}


- (void)sectionedTable:(SectionedTable*)table section:(NSString*)section_id didSelectRow:(NSUInteger)row
{
    [myTableView deselectRow:row inSection:section_id animated:YES];
    
    if ([section_id isEqual:kNeedConnectSection])
    {
	[[BriefcaseAppDelegate sharedAppDelegate] gotoConnectTab];
	return;
    }
    
    // Edit Mode
    if (myTableView.editing)
    {
	NSAssert([section_id isEqual:kUploadSection], @"Wrong section");
	
	NSInteger index = row - [myFixedUploadActions count];
	NSAssert(index>=0,@"Invalid index");
	
	[self editLocationAtIndex:index];
	return;	
    }
    
    FileAction * action = nil;
    
    // Choose button    
    NSInteger count = [myFixedUploadActions count] + [myCustomUploadActions count];
    if ([section_id isEqual:kUploadSection] && row >= count)
    {
	[self chooseLocationAndUpload];
	return;
    }
    else if ([section_id isEqual:kEmailSection])
    {
	[self emailFile];
	return;
    }
    else if ([section_id isEqual:kUploadSection] || [section_id isEqual:kBriefcaseUploadSection])
    {
	if (row < [myFixedUploadActions count])
	    action = [myFixedUploadActions objectAtIndex:row];
	else 
	    action = [myCustomUploadActions objectAtIndex:(row - [myFixedUploadActions count])];	
    }
    else if ([section_id isEqual:kActionSection])
	action = [myFileSpecificActions objectAtIndex:row];
    else
	return;
    
    [self launchAction:action];
}

- (UITableViewCellEditingStyle)sectionedTable:(SectionedTable*)table section:(NSString*)section_id editingStyleForRow:(NSUInteger)row;
{
    if (!self.editing || ![section_id isEqual:kUploadSection])
	return UITableViewCellEditingStyleNone;
    
    if (row < [myFixedUploadActions count])
	return UITableViewCellEditingStyleNone;

    if (row < [myFixedUploadActions count] + [myCustomUploadActions count])
	return UITableViewCellEditingStyleDelete;
    
    if (myTableView.editing && row == [myFixedUploadActions count] + [myCustomUploadActions count])
	return UITableViewCellEditingStyleInsert;
    
    return UITableViewCellEditingStyleNone;
}

#pragma mark Pivate Methods

- (void)updateActiveSectionList
{
    if (myConnection)
    {
	if (myIsBriefcaseConnection)
	{
	    [myTableView setActiveSectionIDs:[NSArray arrayWithObjects:
					      kInformationSection,
#if ! BRIEFCASE_LITE
					      kEmailSection,
#endif
					      kBriefcaseUploadSection,
					      nil]];	    
	}
	else 
	{
	    [myTableView setActiveSectionIDs:[NSArray arrayWithObjects:
					      kInformationSection,
#if ! BRIEFCASE_LITE
					      kEmailSection,
#endif
					      kUploadSection,
					      kActionSection,
					      nil]];
	}
    }
    else {
	[myTableView setActiveSectionIDs:[NSArray arrayWithObjects:
					  kInformationSection,
#if ! BRIEFCASE_LITE
					  kEmailSection,
#endif
					  kNeedConnectSection,
					  nil]];
    }
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
	
	NSLog(@"File Action Count: %d", [myFileSpecificActions count]);
	
	[self _filterActionsForConnection:myConnection];
    }    
    
    myFileInfoCell.attributes = [myFileType getAttributesForFile:file];
    
    myFileInfoCell.icon = [myFileType getPreviewForFile:file];
    
    [myTableView reloadData];
    
    self.navigationItem.title = [file.path lastPathComponent];
}

@end
