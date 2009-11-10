//
//  DownloadController.m
//  Briefcase
//
//  Created by Michael Taylor on 17/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "DownloadController.h"
#import "SFTPDownloadOperation.h"
#import "SSHCommandOperation.h"
#import "SFTPDownloadDirectoryOperation.h"
#import "ConnectionController.h"
#import "File.h"
#import "BCConnectionManager.h"
#import "NetworkOperationQueue.h"
#import "FreeSpaceController.h"
#import "Utilities.h"
#import "SystemInformation.h"

#if BRIEFCASE_LITE
#   import "UpgradeAlert.h"
#endif

DownloadController * theDownloadController = nil;

@implementation DownloadController

+ (DownloadController*)sharedController
{
    if (!theDownloadController)
	theDownloadController = [[DownloadController alloc] init];
    
    return theDownloadController;
}

- (id)init
{
    return [super init];
}

- (NetworkOperation*)downloadFile:(NSString*)path ofSize:(long long)bytes
{
    // Check the size
    FreeSpaceController * free_controller = [FreeSpaceController sharedController];
    long long unreserved_space = free_controller.unreservedSpace;
    if (unreserved_space < bytes)
    {
	// Won't fit
	long long missed_by = bytes - unreserved_space;
	NSString * missed_by_string = [Utilities humanReadibleMemoryDescription:missed_by];
	NSString * message = [NSString stringWithFormat:NSLocalizedString(@"There is not enough space on this device to download \"%@\".  You would require %@ more space.", @"Message displayed when the user tries to download a file to big to fit on this device"),
			      [path lastPathComponent], missed_by_string];
	
	// open an alert with just an OK button
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"File Too Large", @"Title for message telling the user a file is too large for this device") 
							message:message
						       delegate:nil 
					      cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") 
					      otherButtonTitles: nil];
	[alert show];
	[alert release];
		
	return nil;
    }
    
    SFTPDownloadOperation * op = [SFTPDownloadOperation alloc];
    // TODO: Proper username and host
    ConnectionController * controller = [ConnectionController sharedController];
    [op initWithPath:path connection:controller.currentConnection];
    op.reportErrors = YES;
    
    [[NetworkOperationQueue sharedQueue] addOperation:op];
    
    return [op autorelease];
}

- (NetworkOperation*)zipAndDownloadDirectory:(NSString*)path
{
    SFTPDownloadOperation * op = [SFTPDownloadOperation alloc];
    // TODO: Proper username and host
    ConnectionController * controller = [ConnectionController sharedController];
    [op initWithPath:path connection:controller.currentConnection];
    op.reportErrors = YES;
    
    [[NetworkOperationQueue sharedQueue] addOperation:op];
    
    return [op autorelease];
}

#if BRIEFCASE_LITE

- (NetworkOperation*)downloadDirectory:(NSString*)path
{
    UpgradeAlert * alert;
    alert = [[UpgradeAlert alloc] initWithMessage:NSLocalizedString(@"Downloading of directories is supported only in the full version of Briefcase",@"Message informing users that they have to upgrade to get the feature")];
    [alert show];	
    [alert release];

    return nil;
}

#else

- (NetworkOperation*)downloadDirectory:(NSString*)path
{
    ConnectionController * controller = [ConnectionController sharedController];
    SFTPDownloadDirectoryOperation * op = [SFTPDownloadDirectoryOperation alloc];
    [op initWithPath:path connection:controller.currentConnection];
    op.reportErrors = YES;
    
    [[NetworkOperationQueue sharedQueue] addOperation:op];
    
    return [op autorelease];
}

#endif

- (void)resumeIncompleteDownloads
{
    NSArray * incomplete_files = [File incompleteFiles];
    
    for (File * file in incomplete_files)
    {
	[file hydrate];
	
	if (!file.remotePath || [file.remotePath length] == 0 ||
	    !file.remoteHost || [file.remoteHost length] == 0 ||
	    !file.remoteUsername || [file.remoteUsername length] == 0 )
	{
	    // Cannot resume this transfer
	    continue;
	}
	
	SFTPDownloadOperation * op;
	op = [[SFTPDownloadOperation alloc] initWithPath:file.remotePath 
						    host:file.remoteHost 
						username:file.remoteUsername
						    port:file.remotePort];
	op.resumeDownload = YES;
	[[NetworkOperationQueue sharedQueue] addOperation:op];
    }

#if ! BRIEFCASE_LITE
    
    NSArray * ops = [SFTPDownloadDirectoryOperation operationsForUnfinishedJobs];
    for (NetworkOperation * op in ops)
    {
	[[NetworkOperationQueue sharedQueue] addOperation:op];
    }
    
#endif
}

@end
