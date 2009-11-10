//
//  UploadOperation.m
//  Briefcase
//
//  Created by Michael Taylor on 28/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#include <fcntl.h>

#import "SFTPUploadOperation.h"
#import "ConnectionController.h"
#import "SSHConnection.h"
#import "SFTPSession.h"
#import "SFTPFile.h"
#import "BlockingAlert.h"

#define kBlockSize (1024*10)

@implementation SFTPUploadOperation

@synthesize forceOverwrite = myForceOverwrite;

- (id)initWithLocalPath:(NSString*)path 
	     remotePath:(NSString*)remotePath
	     connection:(BCConnection*)connection;
{
    if (self = [super initWithConnection:(SSHConnection*)connection])
    {
	myLocalPath = [path retain];
	myRemotePath = [remotePath retain];
	myForceOverwrite = NO;
    }
    return self;
}

- (id)initWithLocalPath:(NSString*)path 
	     remotePath:(NSString*)remotePath 
		 onHost:(NSString*)host
	       username:(NSString*)username
		   port:(NSInteger)port
{
    if (self = [super initWithHost:host username:username port:port])
    {
	myLocalPath = [path retain];
	myRemotePath = [remotePath retain];
	myForceOverwrite = NO;
    }
    return self;
}

- (void) dealloc
{
    [myRemotePath release];
    [myLocalPath release];
    [super dealloc];
}

- (void)main
{
    NSAssert(myConnection,@"SFTP Session is invalid");
    NSError * error = nil;
    SFTPSession * sftp_session;
    SFTPFile * remote_file = nil;
    NSFileHandle * local_file = nil;
    NSAutoreleasePool * pool;
    
    @try 
    {
	if (!myConnection) return;
	
	sftp_session = [myConnection getSFTPSession];
	
	if (!sftp_session) 
	    [self _raiseException:NSLocalizedString(@"No SFTP connection for download", @"Error message when we have lost our connection")];
	
	NSString * task = [NSString stringWithFormat:NSLocalizedString(@"Uploading file %@",@"Log message when we start uploading a file"),
			   [myLocalPath lastPathComponent]];
	[self beginTask:task];
	
	// Check if the remote file exists
	if (!myForceOverwrite && [sftp_session statRemoteFile:myRemotePath])
	{
	    // The remote file exists, ask the user if they want
	    // to overwrite it
	    NSString * title = NSLocalizedString(@"File Exists", @"Title for warning that a files already exists");
	    NSString * format = NSLocalizedString(@"The remote file \"%@\" already exists.  Do you want to replace it?", @"Message asking user if they want to replace a remote file");
	    NSString * message = [NSString stringWithFormat:format, [myRemotePath lastPathComponent]];
	    
	    BlockingAlert * alert;
	    alert = [[BlockingAlert alloc] initWithTitle:title
						 message:message 
						delegate:nil
				       cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label") 
				       otherButtonTitles:NSLocalizedString(@"OK", @"Label for OK button"), nil];
	    NSInteger answer = [alert showInMainThread];
	    
	    if (answer == 0)
	    {
		[self endTask];
		[self cancel];
		return;
	    }
	}
	
	NSFileManager * manager = [NSFileManager defaultManager];
	NSDictionary * attributes = [manager attributesOfItemAtPath:myLocalPath error:&error];
		
	if (error)
	    [self _raiseException:[error localizedDescription]];
	
	NSUInteger current_position = 0;
	NSNumber * size = [attributes objectForKey:NSFileSize];
	NSUInteger bytes = [size unsignedIntValue];
	
	// Open up the local file
	int file_descriptor = open([myLocalPath UTF8String], O_RDONLY );
	if (file_descriptor)
	    local_file = [[NSFileHandle alloc] initWithFileDescriptor:file_descriptor];
	
	if (!local_file)
	{
	    NSString * error_message = [NSString stringWithFormat:NSLocalizedString(@"Unable to read \"%@\" file on local device", @"Error message when we cannot open a local file on the iPhone"), 
					[myLocalPath lastPathComponent]];
	    [self _raiseException:error_message];
	}
	
	// Open up remote file
	// TODO: File permissions on upload
	remote_file = [sftp_session openRemoteFileForWrite:myRemotePath];
	
	NSLog(@"Starting upload - local %@  remote %@", myLocalPath, myRemotePath);
	    
	NSData * data;
	while (current_position < bytes) 
	{
	    pool = [[NSAutoreleasePool alloc] init];
	    
	    if ([self isCancelled])
	    {
		// The user has cancelled this job
		// Clean up
		[self endTask];
		[self cancel];
		return;
	    }
	    
	    data = [local_file readDataOfLength:kBlockSize];
	    
	    if (data && [data length] > 0)
	    {
		[remote_file writeData:data];
		
		// Notify interested parties of our progress
		current_position += [data length];
		float progress = (float)current_position/(float)bytes;
		[self updateProgress:progress];
	    }
	    else 
	    {
		NSString * error_message = [NSString stringWithFormat:NSLocalizedString(@"Error while reading local file \"%@\" from device", @"Error message when we have a problem reading the local file"), [myLocalPath lastPathComponent]];
		[self _raiseException:error_message];
	    }
	    [pool release];
	}
	
	[self endTask];
    }
    @catch (NSException * exception) {
	NSLog(@"UploadOperation: Exception caught\n  %@", exception);
	[self endTaskWithError:[exception reason]];
    }
    @finally {
	if (remote_file)
	{
	    [remote_file closeFile];
	    [remote_file release];
	}
	
	if (local_file)
	{
	    [local_file closeFile];
	    [local_file release];
	}
    }
}

- (NSString*)title
{
    return NSLocalizedString(@"Uploading", @"Label shown in activity view describing the upload operation");
}

- (NSString*)description
{
    return [myLocalPath lastPathComponent];
}

- (NSString*)identifier
{
    return nil;
}

@end
