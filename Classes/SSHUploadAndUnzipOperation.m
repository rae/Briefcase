//
//  SSHUploadAndUnzipOperation.m
//  Briefcase
//
//  Created by Michael Taylor on 14/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SSHUploadAndUnzipOperation.h"

#import "SystemInformation.h"
#import "SFTPFileAttributes.h"
#import "SFTPSession.h"
#import "BlockingAlert.h"

@implementation SSHUploadAndUnzipOperation


- (id)initWithLocalPath:(NSString*)path 
	     remotePath:(NSString*)remotePath
	     connection:(BCConnection*)connection;
{
    if (self = [super initWithLocalPath:path remotePath:remotePath connection:connection])
    {
    }
    return self;
}

- (id)initWithLocalPath:(NSString*)path 
	     remotePath:(NSString*)remotePath 
		 onHost:(NSString*)host
	       username:(NSString*)username
		   port:(NSInteger)port
{
    if (self = [super initWithLocalPath:path 
			     remotePath:remotePath 
				 onHost:host 
			       username:username 
				   port:port])
    {
    }
    return self;
}

- (void)main
{
    SystemInformation * system_info = [myConnection userData];
    NSString * temp_dir;
    BOOL need_to_delete = NO;
    
    if (system_info)
	temp_dir = system_info.tempDir;
    else
	temp_dir = @"/tmp";
    
    NSString * remote_destination = myRemotePath;
    myRemotePath = [temp_dir stringByAppendingPathComponent:[myLocalPath lastPathComponent]];
    
    // Check that the directory on the other end does not exist
    SFTPSession * sftp_session = [myConnection getSFTPSession];
    SFTPFileAttributes * attributes = [sftp_session statRemoteFile:remote_destination];
    if (attributes)
    {
	// The remote file exists, ask the user if they want
	// to overwrite it
	NSString * title = NSLocalizedString(@"File Exists", @"Title for warning that a files already exists");
	NSString * format = NSLocalizedString(@"The remote file \"%@\" already exists.  Do you want to replace it?", @"Message asking user if they want to replace a remote file");
	NSString * message = [NSString stringWithFormat:format, [remote_destination lastPathComponent]];
	
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
	else
	    need_to_delete = YES;
    }
    
    [super main];
    
    // Delete the old files if necessary
    NSString * command;
    if (need_to_delete)
    {
	command = [NSString stringWithFormat:@"rm -rf \"%@\" > /dev/null", 
		   remote_destination];     
	[myConnection executeCommand:command];
    }
    
    // Unpack the zip file
    command = [NSString stringWithFormat:@"nohup unzip -o -d \"%@\" \"%@\" > /dev/null", 
	       [remote_destination stringByDeletingLastPathComponent], myRemotePath];     
    [myConnection executeCommand:command];
    
    // Delete the zip file
    command = [NSString stringWithFormat:@"rm \"%@\"", myRemotePath];
    [myConnection executeCommand:command];

    // Put back the remote path
    myRemotePath = remote_destination;
}

@end
