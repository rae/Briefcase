//
//  SFTPDownloadDirectory.m
//  Briefcase
//
//  Created by Michael Taylor on 18/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SFTPDownloadDirectoryOperation.h"

#import "SFTPSession.h"
#import "SSHConnection.h"
#import "Utilities.h"
#import "File.h" 
#import "SystemInformation.h"
#import "FreeSpaceController.h"

static NSString * kDirectoryDownloadOperations = @"kDirectoryDownloadOperations";
static NSString * kRemotePath = @"kRemotePath";
static NSString * kRemoteHost = @"kRemoteHost";
static NSString * kRemoteUsername = @"kRemoteUsername";
static NSString * kRemotePort = @"kRemotePort";

#define kFileLimit 2500

@implementation SFTPDownloadDirectoryOperation

+ (NSArray*)operationsForUnfinishedJobs
{    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * unfinished_downloads = [defaults arrayForKey:kDirectoryDownloadOperations];
    [defaults removeObjectForKey:kDirectoryDownloadOperations];
    
    if (!unfinished_downloads)
	return [NSArray array];
    
    NSMutableArray * result = [NSMutableArray array];
    for (NSDictionary * job in unfinished_downloads)
    {
	NSString * host = [job objectForKey:kRemoteHost];
	NSString * username = [job objectForKey:kRemoteUsername];
	NSString * path = [job objectForKey:kRemotePath];
	NSInteger  port = [[job objectForKey:kRemotePort] intValue];
	
	SFTPDownloadDirectoryOperation * op;
	op = [[SFTPDownloadDirectoryOperation alloc] initWithPath:path 
							     host:host 
							 username:username 
							     port:port];
	[result addObject:op];
    }
    return result;
}

- (id)initWithPath:(NSString*)path connection:(SSHConnection*)connection;
{
    if (self = [super initWithConnection:connection])
    {
	myRemotePath = [path retain];
	[self _registerJob:path 
		      host:connection.hostName 
		  username:connection.username 
		      port:connection.port];
	
	// Watch for app quiting
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(_applicationTerminating:) 
		       name:kFileDatabaseWillFinalize 
		     object:nil];
	
    }
    return self;
}

- (id)initWithPath:(NSString*)path 
	      host:(NSString*)host 
	  username:(NSString*)username 
	      port:(NSInteger)port
{
    if (self = [super initWithHost:host username:username port:port])
    {
	myRemotePath = [path retain];
	[self _registerJob:path host:host username:username port:port];
    }
    return self;
}

- (void) dealloc
{
    [myJobAttributes release];
    [myRemotePath release];
    [super dealloc];
}


- (void)_getAllRelativeFilesPathsInRemoteDirectory:(NSString*)remote_directory 
						sftpSession:(SFTPSession*)session
					       relativePath:(NSString*)relative_path
					   resultDictionary:(NSMutableDictionary*)result
{
    NSArray * items = [session readDirectory:remote_directory];
    
    if ([result count] > kFileLimit)
    {
	UIAlertView * alert;
	alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Directory Too Large", @"Title for message telling the user a directory is too large for this device") 
					   message:NSLocalizedString(@"Directory contains too many files to download", @"message telling the user that the directory they are downloading has too many files in it") 
					  delegate:nil
				 cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") 
				 otherButtonTitles:nil];
	[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
	[alert release];
	[self cancel];
	return;
    }
    
    for (SFTPFileAttributes * attributes in items)
    {
	if ([attributes.name isEqualToString:@".DS_Store"])
	    continue;
	
	NSString * new_relative_path = [relative_path stringByAppendingPathComponent:attributes.name];
	if (!attributes.isDir || [Utilities isBundle:attributes.name])
	    [result setObject:attributes forKey:new_relative_path];
	else
	{
	    NSString * sub_path = [remote_directory stringByAppendingPathComponent:attributes.name];
	    [self _getAllRelativeFilesPathsInRemoteDirectory:sub_path
						 sftpSession:session
						relativePath:new_relative_path
					    resultDictionary:result];
	}
	
	if ([self isCancelled])
	    break;
    }
}

- (void)main
{
    NSAutoreleasePool * pool, * loop_pool = nil;
    SFTPSession * sftp_session;
    SFTPFileAttributes * attributes = nil;
    SFTPFile * remote_file = nil;
    NSFileHandle * local_file = nil;
    
    pool = [[NSAutoreleasePool alloc] init];
    
    if (!myConnection) return;
    
    sftp_session = [myConnection getSFTPSession];
    
    SFTPFileDownloader * downloader = [[SFTPFileDownloader alloc] initWithSFTPSession:sftp_session];
    downloader.delegate = self;
    
    NSAssert(sftp_session,@"SFTP Session is invalid");
    if (!sftp_session) return;
    
    NSString * task = [NSString stringWithFormat:NSLocalizedString(@"Downloading file: %@", @"Log message for when a file is downloaded"),
		       [myRemotePath lastPathComponent]];
    
    [self beginTask:task]; 
    
    @try
    {
	NSFileManager * manager = [NSFileManager defaultManager];
	
	// First find all of the files
	NSMutableDictionary * items = [NSMutableDictionary dictionaryWithCapacity:64];
	[self _getAllRelativeFilesPathsInRemoteDirectory:myRemotePath 
					     sftpSession:sftp_session
					    relativePath:[myRemotePath lastPathComponent]
					resultDictionary:items];
	
	if ([self isCancelled])
	{
	    [self endTask];
	    return;
	}
	
	myDownloadCount = [items count];
	myDownloadComplete = 0;
	
	// Check the total size of the download
	long long total_size = 0;
	for (SFTPFileAttributes * file in [items allValues])
	    total_size += file.size;
	FreeSpaceController * free_controller = [FreeSpaceController sharedController];
	if (total_size > free_controller.unreservedSpace)
	{
	    long long missed_by = total_size - free_controller.unreservedSpace;
	    NSString * missed_by_string = [Utilities humanReadibleMemoryDescription:missed_by];
	    NSString * message = [NSString stringWithFormat:NSLocalizedString(@"There is not enough space on this device to download \"%@\".  You would require %@ more space.", @"Message displayed when the user tries to download a file or directory too big to fit on this device"),
				  [myRemotePath lastPathComponent], missed_by_string];
	    UIAlertView * alert;
	    alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Directory Too Large", @"Title for message telling the user a directory is too large for this device") 
					       message:message 
					      delegate:nil
				     cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") 
				     otherButtonTitles:nil];
	    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
	    [alert release];
	    [self endTask];
	    return;
	}
	
	// Get the files
	for (NSString * relative_path in items)
	{
	    loop_pool = [[NSAutoreleasePool alloc] init];
	    
	    NSString * remote_path = [[myRemotePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:relative_path];
	    SFTPFileAttributes * attributes = [items objectForKey:relative_path];
	    File * file = [File fileWithLocalPath:relative_path];
	    
	    // Check if we've got the file already
	    if (file && file.downloadComplete &&
		[remote_path isEqualToString:file.remotePath] &&
		[myConnection.hostName isEqualToString:file.remoteHost] &&
		attributes.size == [file.size longLongValue])
	    {
		// It's the same file, do we have all of it
		NSError * error = nil;
		NSString * local_full_path = [[Utilities pathToDownloads] stringByAppendingPathComponent:file.localPath];
		NSDictionary * local_attributes = [manager attributesOfItemAtPath:local_full_path 
									    error:&error];
		if (error)
		    [self _raiseException:[error localizedDescription]];
		
		NSNumber * size = [local_attributes objectForKey:NSFileSize];
		if ([size longLongValue] == attributes.size)
		{
		    // We've got the file
		    myDownloadComplete++;
		    continue;
		}
	    }
	    
	    [downloader downloadRemoteFile:remote_path 
		      remoteFileAttributes:attributes 
		       toLocalRelativePath:relative_path];
	    
	    if ([self isCancelled])
		break;
	    
	    myDownloadComplete++;
	    
	    [loop_pool release];
	}
	
	
	[self endTask];
    }
    @catch (NSException * exception) 
    {
	NSLog(@"DownloadOperation: Exception caught\n  %@", exception);
	[self endTaskWithError:[exception reason]];
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
	[downloader release];
	
	[self _deregisterJob];
	
	[pool release];
    }
}

- (void)_registerJob:(NSString*)path 
		host:(NSString*)host 
	    username:(NSString*)username 
		port:(NSInteger)port
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    NSArray * current_downloads = [defaults arrayForKey:kDirectoryDownloadOperations];
    NSDictionary * job_attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				     path, kRemotePath,
				     host, kRemoteHost,
				     username, kRemoteUsername,
				     [NSNumber numberWithInt:port], kRemotePort,
				     nil];
    NSArray * new_downloads;
    if (current_downloads)
	new_downloads = [current_downloads arrayByAddingObject:job_attributes];
    else
	new_downloads = [NSArray arrayWithObject:job_attributes];
    
    [defaults setObject:new_downloads forKey:kDirectoryDownloadOperations];
    [defaults synchronize];
    
    myJobAttributes = [job_attributes retain];
}

- (void)_deregisterJob
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * current_downloads = [defaults arrayForKey:kDirectoryDownloadOperations];
    
    if (!current_downloads)
	return;
    
    NSMutableArray * downloads = [NSMutableArray arrayWithArray:current_downloads];
    for (NSDictionary * job in downloads)
    {
	NSLog(@"%@",job);
	if ([[job objectForKey:kRemoteHost] isEqualToString:myHostname] &&
	    [[job objectForKey:kRemoteUsername] isEqualToString:myUsername] &&
	    [[job objectForKey:kRemotePath] isEqualToString:myRemotePath] &&
	    [[job objectForKey:kRemotePort] intValue] == myPort)
	{
	    [downloads removeObject:job];
	    break;
	}
    }
    
    [defaults setObject:downloads forKey:kDirectoryDownloadOperations];
    [defaults synchronize];
    [myJobAttributes release];
    myJobAttributes = nil;
}

- (NSString*)title
{
    return NSLocalizedString(@"Downloading", @"Label shown in activity view describing the download operation");
}

- (NSString*)description
{
    return [myRemotePath lastPathComponent];
}

- (void)sftpFileDownloadProgress:(float)progress
{
    float progress_per_file = 1.0 / (float)myDownloadCount;
    self.progress = ((float)myDownloadComplete + progress) * progress_per_file;
}

- (BOOL)sftpFileDownloadCancelled
{
    return self.isCancelled;
}

- (void)cancel
{
    [super cancel];
    [self _deregisterJob];
}

- (void)_applicationTerminating:(NSNotification*)notification
{
    [super cancel];
}

@end
