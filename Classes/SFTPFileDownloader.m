//
//  SFTPFileDownloader.m
//  Briefcase
//
//  Created by Michael Taylor on 19/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#include <fcntl.h>
#include <stdint.h>

#import "SFTPFileDownloader.h"
#import "SFTPSession.h"
#import "File.h"
#import "SystemInformation.h"
#import "SFTPFile.h"
#import "Utilities.h"
#import "BlockingAlert.h"

#define kBlockSize (1 << 12)
#define kIconCommandFormat @"bzip2 -d -c|python -c \"import sys;eval(compile(sys.stdin.read(),'<stdin>','exec'))\" '%@'"

// Documents with these extensions will be also converted into web archives
NSSet * theWebarchiveExtensions = nil;

@implementation SFTPFileDownloader

@synthesize delegate = myDelegate;

- (id)initWithSFTPSession:(SFTPSession*)session
{
    self = [super init];
    if (self != nil) 
    {
	mySFTPSession = session;
    }
    return self;
}

- (void)downloadRemoteFile:(NSString*)remote_path 
		    toLocalRelativePath:(NSString*)local_path 
{
    SFTPFileAttributes * attributes = [mySFTPSession statRemoteFile:remote_path];
    
    return [self downloadRemoteFile:remote_path 
	       remoteFileAttributes:attributes 
		toLocalRelativePath:local_path];
}

#if BRIEFCASE_LITE

- (NSData*)getWebArchiveFromDocumentAtPath:(NSString*)path
{
    return nil;
}

#else

- (NSData*)getWebArchiveFromDocumentAtPath:(NSString*)path
//
// If we are connected to a Mac running Tiger or better, and this is a 
// document that we need to convert into a webarchive, then do so.
//
{
    NSData * result = nil;
    
    if (!theWebarchiveExtensions)
    {
	theWebarchiveExtensions = [[NSSet setWithObjects:
				    @"rtf", 
				    @"rtfd", 
				    @"odt", 
				    nil] retain];
    }
    
    SystemInformation * info = mySFTPSession.connection.userData;
    if ([theWebarchiveExtensions containsObject:[[path pathExtension] lowercaseString]] &&
	info && [info isConnectedToMac] && [info darwinVersion] >= 8.0)
    {
	// Extract a webarchive of the document
	NSString * command;
	command = [NSString stringWithFormat:@"/usr/bin/textutil -stdout "
		   @"-convert webarchive '%@'", path];
	result = [mySFTPSession.connection executeCommand:command];
    }
    
    return result;
}

#endif

- (void)getIcon:(NSData**)icon andPreview:(NSData**)preview atPath:(NSString*)path;
{
    *icon = nil;
    *preview = nil;
    
    // Check if we are connected to a Mac running Leopard or better.
    // If so, try to grab an icon
    SystemInformation * info = mySFTPSession.connection.userData;
    if (info && [info isConnectedToMac] && [info darwinVersion] >= 9.0)
    {
	NSData * file_data = nil;
	NSDictionary * dict = nil;
	NSData * icon_helper = [Utilities getResourceData:@"thumbnail_grab.py.bz2"];
	NSString * command = [NSString stringWithFormat:kIconCommandFormat, path];
	@try 
	{
	    file_data = [[mySFTPSession.connection executeCommand:command withInput:icon_helper] retain];
	    dict = [[NSKeyedUnarchiver unarchiveObjectWithData:file_data] retain];
	    if (dict)
	    {
		*icon = [dict objectForKey:@"icon"];
		*preview = [dict objectForKey:@"preview"];
	    }
	}
	@catch (NSException*) 
	{
	    NSLog(@"Could not grab icon for remote file");
	    
	    if (!mySFTPSession.connection.isConnected)
		// If we've lost the connection, then re-throw the
		// exception
		@throw;
	}
	@finally {
	    [file_data release];
	    [dict release];
	}
    }
}

- (void)downloadRemoteFile:(NSString*)remote_path 
      remoteFileAttributes:(SFTPFileAttributes*)attributes
       toLocalRelativePath:(NSString*)local_path 
{ 
    SFTPFile * remote_file = nil;
    NSFileHandle * local_file = nil;
    
    @try
    {
	NSString * original_remote_path = remote_path;   
	long long remaining_bytes, downloaded_bytes;
	BOOL is_zipped = NO;
	BOOL ok_to_resume = NO;
	
	if (!attributes)
	    [self _raiseException:NSLocalizedString(@"Unable to read properties of remote file",@"Error message for when Briefcase cannot read a file's properties")];
	
	// It's a bundle, need to zip it
	if (attributes.isDir)
	{	
	    // Find the temp directory, we may need it
	    SystemInformation * system_info = [mySFTPSession.connection userData];
	    NSString * temp_dir;
	    if (system_info)
		temp_dir = system_info.tempDir;
	    else
		temp_dir = @"/tmp";
	    
	    NSString * zip_name = [[remote_path lastPathComponent] stringByAppendingString:@".zip"];
	    NSString * temp_zip_file = [temp_dir stringByAppendingPathComponent:zip_name];
	    
	    // Zip the file remotely
	    NSString * zip_command = [NSString stringWithFormat:@"cd \"%@\";zip -r \"%@\" \"%@\"",
				      [remote_path stringByDeletingLastPathComponent],
				      temp_zip_file, [remote_path lastPathComponent]];
	    [mySFTPSession.connection executeCommand:zip_command];
	    remote_path = temp_zip_file;
	    local_path = [local_path stringByAppendingString:@".zip"];
	    
	    // Get the attributes of the zip file so we know the size
	    attributes = [mySFTPSession statRemoteFile:remote_path];
	    is_zipped = YES;
	}
	
	// Check if we've got a partially downloaded file
	File * file_record = [File fileWithLocalPath:local_path];
	if (file_record &&  
	    attributes.size == [file_record.size longLongValue] &&
	    [attributes.modificationTime isEqualToDate:file_record.remoteModificationTime] &&
	    [file_record.remoteHost isEqualToString:mySFTPSession.connection.hostName] &&
	    [file_record.remoteUsername isEqualToString:mySFTPSession.connection.username] )
	{
	    if (file_record.downloadComplete)
		// It looks like we've already got a copy of this file
		return;
	    
	    // If all of this is true, then we'll try to resume the download
	    ok_to_resume = YES;
	}
	
//	NSLog(@"File Download: %@", local_path);
//	NSLog(@" - %@", file_record);
//	NSLog(@" - download complete: %d", (int)file_record.downloadComplete);
//	NSLog(@" - size: %qi vs %qi", attributes.size, [file_record.size longLongValue]);
	
	// Check if the local file exists	
	NSString * download_path = [[Utilities pathToDownloads] stringByAppendingPathComponent:local_path];
	NSFileManager * manager = [NSFileManager defaultManager];
	if (!ok_to_resume && [manager fileExistsAtPath:download_path])
	{
	    // The remote file exists, ask the user if they want
	    // to overwrite it
	    NSString * title = NSLocalizedString(@"File Exists", @"Title for warning that a files already exists");
	    NSString * format = NSLocalizedString(@"\"%@\" already exists in Briefcase.  Do you want to replace it?", @"Message asking user if they want to replace a local file");
	    NSString * message = [NSString stringWithFormat:format, [local_path lastPathComponent]];
	    
	    BlockingAlert * alert;
	    alert = [[BlockingAlert alloc] initWithTitle:title
						 message:message 
						delegate:nil
				       cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label") 
				       otherButtonTitles:NSLocalizedString(@"OK", @"Label for OK button"), nil];
	    NSInteger answer = [alert showInMainThread];
	    [alert release];
	    
	    if (answer == 0)
		return;
	}
	
	// Create a record in our database
	if (!file_record)
	    file_record = [File getOrCreateFileWithLocalPath:local_path];
	file_record.size = [NSNumber numberWithUnsignedInt:attributes.size];
	file_record.isZipped = is_zipped;
	file_record.downloadComplete = NO;
	file_record.remotePath = original_remote_path;
	file_record.remoteMode = attributes.permissions;
	file_record.remoteHost = mySFTPSession.connection.hostName;
	file_record.remoteUsername = mySFTPSession.connection.username;
	file_record.remotePort = mySFTPSession.connection.port;
	file_record.remoteModificationTime = attributes.modificationTime;
	[file_record save];
	
	remaining_bytes = attributes.size;
	downloaded_bytes = 0;
	
	// Check if we are connected to a Mac running Leopard or better.
	// If so, try to grab an icon
	NSData * icon_data = nil, * preview_data = nil;
	[self getIcon:&icon_data andPreview:&preview_data atPath:original_remote_path];
	if (icon_data)
	    file_record.iconData = icon_data;
	if (preview_data)
	    file_record.previewData = preview_data;
	
	// If we are connected to a Mac, and we need to convert this file to
	// view it, then do so
	NSData * webarchive_data;
	webarchive_data = [self getWebArchiveFromDocumentAtPath:original_remote_path];
	if (webarchive_data)
	    file_record.webArchiveData = webarchive_data;
	else
	    file_record.webArchiveData = nil;
	
	NSUInteger current_position = 0;
	NSUInteger file_length = attributes.size;
	
	// Open up the remote file
	remote_file = [mySFTPSession openRemoteFileForRead:remote_path];
	if (!remote_file) 
	{
	    NSString * error = [NSString stringWithFormat:NSLocalizedString(@"Unable to open remote file \"%@\"",@"Error message when Briefcase cannot open a remote file"), 
				[remote_path lastPathComponent]];
	    [self _raiseException:error];
	}
	
	// Check that the local directory exits
	BOOL is_dir;
	NSError * error = nil;
	NSString * local_directory = [file_record.path stringByDeletingLastPathComponent];
	if (![manager fileExistsAtPath:local_directory isDirectory:&is_dir])
	{
	    [manager createDirectoryAtPath:local_directory 
	       withIntermediateDirectories:YES 
				attributes:nil 
				     error:&error];
	    if (error)
		[self _raiseException:[error localizedDescription]];
	}
	else if (!is_dir)
	{
	    // It's currently a file
	    // TODO: ask user about removing file
	    File * file = [File fileWithLocalPath:local_directory];
	    if (file)
		[file delete];
	    [manager createDirectoryAtPath:local_directory 
	       withIntermediateDirectories:YES 
				attributes:nil 
				     error:&error];
	    if (error)
		[self _raiseException:[error localizedDescription]];		
	}
	
	// Open up the local file
	int open_flags = O_WRONLY|O_CREAT|O_APPEND;
	if (!ok_to_resume)
	    open_flags |= O_TRUNC;
	
	int file_descriptor = open([file_record.path UTF8String], open_flags, 0666);
	
	local_file = [[NSFileHandle alloc] initWithFileDescriptor:file_descriptor];
	if (!local_file)
	{
	    NSString * error = [NSString stringWithFormat:NSLocalizedString(@"Unable to write file \"%@\" to iPhone",@"Error message when Briefcase cannot open a local file"), 
				[file_record.path lastPathComponent]];
	    [self _raiseException:error];
	}
	
	if (ok_to_resume)
	{
	    // Try to seek in the remote file
	    [local_file seekToEndOfFile];
	    unsigned long long offset = [local_file offsetInFile];
	    if (offset < INT32_MAX)
	    {
		[remote_file seekToFileOffset:(int)offset];
		current_position = offset;
	    }
	    else
	    {
		NSString * error = [NSString stringWithFormat:NSLocalizedString(@"Unable to resume download of file \"%@\".  File is too large",@"Error message when Briefcase cannot resume a download because the file is larger than 2Gb"), 
				    [file_record.path lastPathComponent]];
		[self _raiseException:error];
	    }
	}
	
	NSData * data;
	while (current_position < file_length) 
	{
	    if (myDelegate && [myDelegate sftpFileDownloadCancelled])
	    {
		// The user has cancelled this job
		// Clean up
		[file_record delete];
		return;
	    }
	    
	    data = [remote_file readDataOfLength:kBlockSize];
	    if (data && [data length] > 0)
	    {
		[local_file writeData:data];
		remaining_bytes -= [data length];
		downloaded_bytes += [data length];
		
		// Notify interested parties of our progress
		current_position += [data length];
		float progress = (float)current_position/(float)file_length;
		if (myDelegate)
		    [myDelegate sftpFileDownloadProgress:progress];

	    }
	    else
	    {
		NSString * error = [NSString stringWithFormat:NSLocalizedString(@"Download of file \"%@\" ended prematurely", @"Error message when a file download ends before the whole file is downloaded"), 
				    [remote_path lastPathComponent]];
		[self _raiseException:error];
	    }
	}
	
	file_record.downloadComplete = YES;
	[file_record save];
	
	// If it's a bundle, remove the zip
	if (attributes.isDir)
	    // Delete the temporary zip file
	    [mySFTPSession deleteFile:remote_path];
	}
    @finally 
    {
	if (remote_file)
	    [remote_file closeFile];
	if (local_file)
	    [local_file closeFile];
	
	[attributes release];
	[remote_file release];
	[local_file release];
    }
}

-(void)_raiseException:(NSString*)description
{
    NSException * exception = [NSException exceptionWithName:NSLocalizedString(@"Network Operation Error", @"Title for dialogs that show error messages about failed network operations")
						      reason:description
						    userInfo:nil];
    @throw exception;
}


@end
