//
//  SFTPFile.m
//  Briefcase
//
//  Created by Michael Taylor on 17/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SFTPFile.h"
#import "SSHConnection.h"

@implementation SFTPFile

- (id)initWithFile:(LIBSSH2_SFTP_HANDLE*)file
{
    if (self = [super init])
    {
	myFile = file;	
	if (myFile)
	{
	    //sftp_file_set_nonblocking(myFile);
	}
	myReturnData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [myReturnData release];
    [super dealloc];
}

- (void)closeFile
{
    if (myFile)
    {
	[[SSHConnection sshLock] lock];
	libssh2_sftp_close(myFile);
	[[SSHConnection sshLock] unlock];
    }
    
    [myReturnData release];
    myReturnData = nil;
}

- (void)writeData:(NSData*)data
{
    if (myFile)
    {
	[[SSHConnection sshLock] lock];
	int result = libssh2_sftp_write(myFile, (void*)[data bytes], [data length]);
	[[SSHConnection sshLock] unlock];
	
	if (result < [data length])
	    [self _raiseException:NSLocalizedString(@"An error occurred while writing to the remote file", @"Error message for remote write error")];
    }
}

- (NSData*)readDataOfLength:(NSUInteger)length
{
    if (myFile)
    {
	[myReturnData setLength:length];
	
	[[SSHConnection sshLock] lock];
	int result = libssh2_sftp_read(myFile, [myReturnData mutableBytes], length);
	[[SSHConnection sshLock] unlock];
	
	if (result > 0)
	{
	    [myReturnData setLength:result];
	    return myReturnData;
	}
    }
    
    return nil;
}

- (void)seekToFileOffset:(NSInteger)offset
{
    if (myFile)
    {
	[[SSHConnection sshLock] lock];
	libssh2_sftp_seek(myFile, offset);
	[[SSHConnection sshLock] unlock];
    }
}

- (NSUInteger)position
{
    NSUInteger result = 0;
    if (myFile)
    {
	[[SSHConnection sshLock] lock];
	result = (NSUInteger)libssh2_sftp_tell(myFile);
	[[SSHConnection sshLock] unlock];
    }
    
    return result;
}

- (void)seekToBeginningOfFile
{
    if (myFile)
    {
	[[SSHConnection sshLock] lock];
	libssh2_sftp_rewind(myFile); 
	[[SSHConnection sshLock] unlock];   
    }
}

- (void)_raiseException:(NSString*)message
{
    NSException * exception;
    exception = [NSException exceptionWithName:NSLocalizedString(@"Network Operation Error", @"Title for dialogs that show error messages about failed network operations") 
					reason:message 
				      userInfo:nil];
    @throw exception;    
}

@end
