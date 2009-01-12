//
//  DownloadOperation.m
//  Briefcase
//
//  Created by Michael Taylor on 17/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SFTPDownloadOperation.h"
#import "SFTPSession.h"
#import "SSHConnection.h"
#import "File.h"

#define kBlockSize (1024*100)

@implementation SFTPDownloadOperation

@synthesize resumeDownload = myResumeDownload;
@synthesize markAsZipped = myMarkAsZipped;
@synthesize remainingBytes = myRemainingBytes;
@synthesize downloadedBytes = myDownloadedBytes;

- (id)initWithPath:(NSString*)path connection:(SSHConnection*)connection;
{
    if (self = [super initWithConnection:connection])
    {
	myRemotePath = [path retain];
	myRemoteSource = nil;
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
	myRemoteSource = nil;
	myMarkAsZipped = NO;
    }
    return self;
}

- (void) dealloc
{
    [myRemotePath release];
    [myRemoteSource release];
    [super dealloc];
}

- (void)_getIcon:(NSData**)icon andPreview:(NSData**)preview
{
    [self getIcon:icon andPreview:preview atPath:myRemoteSource];
}

- (void)main
{
    SFTPSession * sftp_session;
    
    if (!myConnection) return;
    
    sftp_session = [myConnection getSFTPSession];
    
    NSAssert(sftp_session,@"SFTP Session is invalid");
    if (!sftp_session) return;
    
    NSString * task = [NSString stringWithFormat:NSLocalizedString(@"Downloading file: %@", @"Log message for when a file is downloaded"),
		       [myRemotePath lastPathComponent]];
    [self beginTask:task]; 
    
    @try
    {
	SFTPFileDownloader * downloader = [[SFTPFileDownloader alloc] initWithSFTPSession:sftp_session];
	downloader.delegate = self;
	
	[downloader downloadRemoteFile:myRemotePath 
		   toLocalRelativePath:[myRemotePath lastPathComponent]];
	[downloader release];
    }
    @catch (NSException * exception) 
    {
	NSLog(@"DownloadOperation: Exception caught\n  %@", exception);
	[self endTaskWithError:[exception reason]];
    }
    
    [self endTask];
}

- (NSString*)title
{
    return NSLocalizedString(@"Downloading", @"Label shown in activity view describing the download operation");
}

- (NSString*)description
{
    return [myRemotePath lastPathComponent];
}

- (void)cancel
{
    [super cancel];
    if (myResumeDownload && ![self isExecuting] && ![self isFinished])
    {
	// We need to remove the database entry, or this
	// will start back up the next time we launch
	NSString * local_file = [myRemotePath lastPathComponent];
	[File deleteFileAtLocalPath:local_file];
    }
}

- (void)sftpFileDownloadProgress:(float)progress
{
    self.progress = progress;
}

- (BOOL)sftpFileDownloadCancelled
{
    return self.isCancelled;
}

@end
