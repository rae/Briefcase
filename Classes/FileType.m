//
//  FileType.m
//  Briefcase
//
//  Created by Michael Taylor on 03/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "FileType.h"
#import "File.h"
#import "Utilities.h"
#import "BriefcaseUploadOperation.h"
#import "FileAction.h"
#import "IconManager.h"
#import "CustomLocationAction.h"
#import "SSHConnection.h"
#import "HostPrefs.h"
#import "DocumentViewController.h"
#import "BriefcaseAppDelegate.h"
#import "UpgradeAlert.h"

NSString * kFileAttributeAdded = @"File Attributs Added";

static NSMutableArray * theFileTypes = nil;

@implementation FileType

@synthesize weight = myWeight;

+ (FileType*)findBestMatch:(File*)file
{
    FileType * best_match = nil;
    for (FileType * type in theFileTypes)
	if ([type matchesFileType:file] && (!best_match || best_match.weight < type.weight))
	    best_match = type;
    return best_match;
}

- (id)initWithWeight:(NSInteger)weight
{    
    self = [super init];
    if (self != nil) 
    {
	myWeight = weight;
	
	if (!theFileTypes)
	    theFileTypes = [[NSMutableArray alloc] init];
	
	[theFileTypes addObject:self];
    }
    return self;
}

- (BOOL)matchesFileType:(File*)file
{
    BOOL result = NO;
    
    if (myExtentions)
	result = [myExtentions containsObject:file.fileExtension];
    else
	// If we've got no extension list, accept everything
	result = YES;
    
    return result;
}

- (BOOL)isViewable
{
    return YES;
}

- (void)viewFile:(File*)file
{	 
#if BRIEFCASE_LITE
    UpgradeAlert * alert;
    alert = [[UpgradeAlert alloc] initWithMessage:NSLocalizedString(@"This document type is not supported in Briefcase Lite.",@"Message informing users that they have to upgrade to view more file types")];
    [alert show];	
    [alert release];    
#else 
    DocumentViewController * file_view;
    file_view = [DocumentViewController documentViewControllerForFile:file];
    [[BriefcaseAppDelegate sharedAppDelegate] pushFullScreenView:file_view 
					      withStatusBarStyle:UIStatusBarStyleBlackOpaque];
#endif
}

- (NSArray*)getUploadActions
{
    FileAction * desktop_action, * downloads_action;
    
    desktop_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Desktop", @"Desktop folder in the user's directory") 
					      target:self 
					    selector:@selector(uploadToDesktopWithFile:connection:) 
					 requiresMac:NO];
    
    downloads_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Downloads", @"Downloads folder in the user's directory")
						target:self 
					      selector:@selector(uploadToDownloadsWithFile:connection:) 
					   requiresMac:NO];
    
    NSArray * general_actions = [NSArray arrayWithObjects:desktop_action, downloads_action, nil];
    NSArray * type_specific_actions = [self getUploadActionsForType];
    return [general_actions arrayByAddingObjectsFromArray:type_specific_actions];
}

- (NSArray*)getUploadActionsForType
{
    return [NSArray array];
}

- (NSArray*)getFileSpecificActions
{
    FileAction * open_action;
    
    open_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Open on Mac", @"Label for file action that opens a document on a connected Macintosh computer")
					   target:self 
					 selector:@selector(openFileOnMac:connection:) 
				      requiresMac:YES];
    
    return [NSArray arrayWithObjects:open_action, nil];
}

- (NSArray*)getBriefcaseActions
{
    FileAction * upload_action;
    
    upload_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Upload to Briefcase", @"Button allowing a user to upload to another iPhone user's copy of Briefcase")
					     target:self 
					   selector:@selector(uploadToBriefcase:connection:) 
					requiresMac:NO];
    
    return [NSArray arrayWithObjects:upload_action, nil];
}

- (NSArray*)getAttributesForFile:(File*)file
{
    NSFileManager * manager = [NSFileManager defaultManager];
    NSDictionary * attributes = [manager attributesOfItemAtPath:file.path error:NULL];
    
    NSUInteger bytes = [attributes fileSize];
    
    NSString * length_string = [Utilities humanReadibleMemoryDescription:bytes];
    
    // TODO: Error checking
    NSArray * file_name = [NSArray arrayWithObjects:NSLocalizedString(@"name", 
								      @"Label for information field that displays the name of the file"),
			   file.fileName,
			   nil];
    NSArray * file_size = [NSArray arrayWithObjects:NSLocalizedString(@"size", 
								      @"Label for information field that displays the size of the file"), 
			   length_string, nil];
    
    NSDateFormatter * formatter = [[[NSDateFormatter alloc] init]  autorelease];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSString * date_string = [formatter stringFromDate:file.remoteModificationTime];
    
    NSArray * file_data = [NSArray arrayWithObjects:NSLocalizedString(@"date", 
								      @"Label for information field that displays the modified data of the file"), 
			   date_string, nil];
    return [NSArray arrayWithObjects:file_name, file_size, file_data, nil];
}

- (UIImage*)getPreviewForFile:(File*)file
{
    UIImage * preview = file.previewImage;
    if (!preview)
	preview = file.iconImage;
    if (!preview)
	preview = [IconManager iconForFile:file.fileName smallIcon:NO];
    return preview;
}

#pragma mark Action Implementations

- (NSArray*)uploadToDesktopWithFile:(File*)file connection:(Connection*)connection
{
    NSString * remote_path = @"Desktop";
    return [FileAction operationsForUploadOfFile:file toPath:remote_path];
}

- (NSArray*)uploadToDownloadsWithFile:(File*)file connection:(Connection*)connection
{
    NSString * remote_path = @"Downloads";
    return [FileAction operationsForUploadOfFile:file toPath:remote_path];
}

- (NSArray*)uploadToCustomLocationWithFile:(File*)file connection:(Connection*)connection
{
    NSString * remote_path = @"Downloads";
    return [FileAction operationsForUploadOfFile:file toPath:remote_path];
}

- (NSArray*)openFileOnMac:(File*)file connection:(Connection*)connection
{
    return [FileAction operationsForUploadOfFile:file withRemoteShellCommand:@"/usr/bin/open \"%@\""];
}

- (NSArray*)uploadToBriefcase:(File*)file connection:(Connection*)connection
{
    NSArray * result = nil;
    
    BriefcaseUploadOperation * op;
    op = [[BriefcaseUploadOperation alloc] initWithConnection:(BriefcaseConnection*)connection file:file];
    result = [NSArray arrayWithObject:op];
    [op release];
	   
    return result;
}

@end
