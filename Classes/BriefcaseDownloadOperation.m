//
//  BriefcaseDownloadOperation.m
//  Briefcase
//
//  Created by Michael Taylor on 14/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BriefcaseDownloadOperation.h"
#import "BlockingAlert.h"
#import "Utilities.h"
#import "File.h"
#import "BriefcaseConnection.h"
#import "HMWorkerThread.h"

#include <fcntl.h>

@implementation BriefcaseDownloadOperation

@synthesize connection = myBriefcaseConnection;

+ (BOOL)okToDownload:(NSDictionary*)header
{
    NSString * filename = [[header objectForKey:@"filename"] retain];
    NSString * download_path = [[Utilities pathToDownloads] stringByAppendingPathComponent:filename];
    
    NSNumber * is_zipped_number = [header objectForKey:@"zipped"];
    BOOL is_zipped = NO;
    if (is_zipped_number && [is_zipped_number boolValue])
	is_zipped = YES;
    
    // Check if the file exists already
    NSFileManager * manager = [NSFileManager defaultManager];
    if (is_zipped)
	download_path = [download_path stringByAppendingString:@".zip"];
    if ([manager fileExistsAtPath:download_path])
    {
	// The remote file exists, ask the user if they want
	// to overwrite it
	NSString * title = NSLocalizedString(@"File Exists", @"Title for warning that a files already exists");
	NSString * format = NSLocalizedString(@"\"%@\" already exists in Briefcase.  Do you want to replace it?", @"Message asking user if they want to replace a local file");
	NSString * message = [NSString stringWithFormat:format, filename];
	
	BlockingAlert * alert;
	alert = [[BlockingAlert alloc] initWithTitle:title
					     message:message 
					    delegate:nil
				   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label") 
				   otherButtonTitles:NSLocalizedString(@"OK", @"Label for OK button"), nil];
	NSInteger answer = [alert showInMainThread];
	
	if (answer == 0)
	    return NO;
    }    
    return YES;
}

- (id)initWithFileHeader:(NSDictionary*)header
{
    self = [super init];
    if (self != nil) 
    {
	myFilename = [[header objectForKey:@"filename"] retain];
	NSString * local_path = [[Utilities pathToDownloads] stringByAppendingPathComponent:myFilename];
	
	NSNumber * is_zipped_number = [header objectForKey:@"zipped"];
	BOOL is_zipped = NO;
	if (is_zipped_number && [is_zipped_number boolValue])
	    is_zipped = YES;	
	
	// Set up the local file for writing to
	myFile = [[File getOrCreateFileWithLocalPath:myFilename] retain];
	myFile.size = [header objectForKey:@"size"];
	myFile.isZipped = is_zipped;
	myFile.downloadComplete = NO;
	myFile.remotePath = @"";
	myFile.remoteMode = 0666;
	myFile.remoteHost = @"";
	myFile.remoteUsername = @"";
	myFile.remoteCreationTime = [NSDate date];
	myFile.remoteModificationTime = [NSDate date];
	[myFile save];
	
	int open_flags = O_WRONLY|O_CREAT|O_APPEND|O_TRUNC;
	int file_descriptor = open([local_path UTF8String], open_flags, 0666);
	
	if (open < 0)
	    return self;

	myFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:file_descriptor];
	if (!myFileHandle)
	    return self;
	
	myBytesWritten = 0;
	
	myIconData	    = [[header objectForKey:@"icon"] retain];
	myPreviewData	    = [[header objectForKey:@"preview"] retain];
	myWebArchiveData    = [[header objectForKey:@"webarchive"] retain];
		
	myCondition = [[NSCondition alloc] init];
	myLocalUserCancelled = NO;
    }
    return self;
}

- (void) dealloc
{
    [myFile release];
    [myFileHandle release];
    [myFilename release];
    [myIconData release];
    [myPreviewData release];
    [myWebArchiveData release];
    [myCondition release];
    
    [super dealloc];
}

-(void)main
{
    [self beginTask:NSLocalizedString(@"Receiving File", @"Log message when an upload begins")];
    
    @try 
    {
	if (!myFileHandle)
	{
	    NSString * error = [NSString stringWithFormat:NSLocalizedString(@"Unable to write file \"%@\" to iPhone",@"Error message when Briefcase cannot open a local file"), 
				myFilename];
	    [self _raiseException:error];	    
	}
	
	[myCondition lock];
	
	while (myFileHandle) {
	    [myCondition wait];
	}
	
	[myCondition unlock];
    }
    @catch (NSException * exception) 
    {
	[self endTaskWithError:[exception reason]];
    }
    @finally 
    {	
	if (myFileHandle)
	{
	    [myFileHandle closeFile];
	}
    }
}

- (void)addData:(NSData*)data
{
    NSAssert(myFileHandle,@"No file handle for writing!");
    if (!myFileHandle)
	return;
    
    [myFileHandle writeData:data];
    myBytesWritten += [data length];
    
    long long file_size = [myFile.size longLongValue];
    self.progress = (float)myBytesWritten / (float)file_size;
}

- (void)done
{
    [self performSelector:@selector(_done) 
		 onThread:[BriefcaseConnection briefcaseConnectionThread] 
	       withObject:nil 
	    waitUntilDone:NO];
}

- (void)_done
{
    long long file_size = [myFile.size longLongValue];
    if (myBytesWritten == file_size)
    {
	// File is the right size
	if (myIconData)
	    myFile.iconData = myIconData;
	if (myPreviewData)
	    myFile.previewData = myPreviewData;
	if (myWebArchiveData)
	    myFile.webArchiveData = myWebArchiveData;
	    
	myFile.downloadComplete = YES;
	[myFile save];
	
	[self endTask];
    }
    else if (myBytesWritten < file_size)
    {
	if (myLocalUserCancelled)
	{
	    if (myFile)
	    {
		[myFile delete];
		[myFile release];
		myFile = nil;
	    }
	}
	else
	{
	    // Incomplete download.  Warn the user and turf the file
	    NSString * title = NSLocalizedString(@"Incomplete Download", @"Title for warning when a download is incomplete");
	    NSString * format = NSLocalizedString(@"Only part of the file \"%@\" was received.  Do you wish to delete the partial file?", @"Message telling the user that only part of a file was received");
	    NSString * message = [NSString stringWithFormat:format, myFile.fileName];
	    
	    BlockingAlert * alert;
	    alert = [[BlockingAlert alloc] initWithTitle:title
						 message:message 
						delegate:nil
				       cancelButtonTitle:NSLocalizedString(@"Delete", @"Delete partial file") 
				       otherButtonTitles:NSLocalizedString(@"Keep", @"Keep partial file"), nil];
	    NSInteger answer = [alert showInMainThread];
	    
	    if (answer == 0)
	    {
		if (myFile)
		{
		    [myFile delete];
		    [myFile release];
		    myFile = nil;
		}
	    }
	    else
	    {
		// Truncate the file
		myFile.size = [NSNumber numberWithLongLong:myBytesWritten];
		myFile.downloadComplete = YES;
		[myFile save];
		[myFile release];
		myFile = nil;
	    }
	}
	
	[self endTaskWithError:@"File download incomplete"];
    }
    else if (myBytesWritten > file_size)
    {
	// Something is very wrong
	if (myFile)
	{
	    [myFile delete];
	    [myFile release];
	    myFile = nil;
	}
	[self endTaskWithError:@"File download overrun"];
    }
    [myFileHandle closeFile];
    [myFileHandle release];
    myFileHandle = nil;
    [myCondition lock];
    [myCondition signal];
    [myCondition unlock];
}

- (void)cancel
{
    [super cancel];
    
    myLocalUserCancelled = YES;
    
    if (myFileHandle)
    {
	[myFileHandle closeFile];
	[myFileHandle release];
	myFileHandle = nil;
    }
    if (myFile)
    {
	[myFile delete];
	[myFile release];
	myFile = nil;
    }
    
    [myCondition lock];
    [myCondition signal];
    [myCondition unlock];
}

- (NSString*)title
{
    return NSLocalizedString(@"Downloading", @"Label shown in activity view describing the download operation");
}

- (NSString*)description
{
    return myFilename;
}

- (NSString*)identifier
{
    return nil;
}


@end
