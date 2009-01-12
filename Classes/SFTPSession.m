//
//  SFTPSession.m
//  Briefcase
//
//  Created by Michael Taylor on 06/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SFTPSession.h"
#import "SFTPFileAttributes.h"
#import "SSHConnection.h"

#import <fcntl.h>
#import <sys/stat.h>

@implementation SFTPSession

@synthesize connection = myConnection;

-(id)initWithConnection:(SSHConnection*)connection
{
    myConnection = connection;
    
    [[SSHConnection sshLock] lock];
    mySession = libssh2_sftp_init(connection.session);
    [[SSHConnection sshLock] unlock];
    
    return [super init];
}

-(NSArray*)readDirectory:(NSString*)path
{
    NSMutableArray * result = nil;
    
    if (mySession)
    {
	int name_length;
	char name_buffer[FILENAME_MAX];
	LIBSSH2_SFTP_ATTRIBUTES attributes;
	
	[[SSHConnection sshLock] lock];
	LIBSSH2_SFTP_HANDLE * dir = libssh2_sftp_opendir(mySession, (char*)[path UTF8String]);
	[[SSHConnection sshLock] unlock];
	
	if (!dir)
	    [self _raiseSFTPException];
	
	if (dir)
	{
	    result = [[NSMutableArray alloc] initWithCapacity:6];
	    
	    [[SSHConnection sshLock] lock];
	    name_length = libssh2_sftp_readdir(dir, name_buffer, FILENAME_MAX, &attributes);
	    [[SSHConnection sshLock] unlock];
	    
	    while (name_length > 0) 
	    {
		if (0 != strcmp(name_buffer, ".") && 0 != strcmp(name_buffer, ".."))
		{
		    NSString * name_string = [NSString stringWithUTF8String:name_buffer];
		    
		    if (S_ISLNK(attributes.permissions))
		    {
			NSString * link_path = [path stringByAppendingPathComponent:name_string];
			[[SSHConnection sshLock] lock];
			libssh2_sftp_stat(mySession, (char*)[link_path UTF8String], &attributes);
			[[SSHConnection sshLock] unlock];
		    }
		    [result addObject:[[SFTPFileAttributes alloc] initWithAttributes:&attributes filename:name_string]];
		}
		[[SSHConnection sshLock] lock];
		name_length = libssh2_sftp_readdir(dir, name_buffer, FILENAME_MAX, &attributes);
		[[SSHConnection sshLock] unlock];
	    }
	    
	    [[SSHConnection sshLock] lock];
	    libssh2_sftp_closedir(dir);
	    [[SSHConnection sshLock] unlock];
	}
    }
    
    return result;
}

-(SFTPFile*)_openRemoteFile:(NSString*)path withFlags:(NSUInteger)flags mode:(NSInteger)mode
{
    if (mySession)
    {
	[[SSHConnection sshLock] lock];
	LIBSSH2_SFTP_HANDLE * file = libssh2_sftp_open(mySession, (char*)[path UTF8String], flags, mode);
	[[SSHConnection sshLock] unlock];
	
	if (file)
	    return [[SFTPFile alloc] initWithFile:file];
	else
	{
	    char * errmsg = NULL;
	    
	    [[SSHConnection sshLock] lock];
	    int error = libssh2_sftp_last_error(mySession);
	    [[SSHConnection sshLock] unlock];
	    
	    if (errmsg)
		NSLog(@"Error message: %d", errmsg);
	    
	    NSString * error_message;
	    switch (error) {
		case LIBSSH2_FX_PERMISSION_DENIED:
		    error_message = NSLocalizedString(@"Access to file denied",
						      @"Error message for an access denied error");
		    break;
		default:
		    error_message = NSLocalizedString(@"Unknown error",
						      @"Error message when an unknown error has occurred");
	    }
	}
    }
    return nil;
}

-(SFTPFile*)openRemoteFileForRead:(NSString*)path
{
    return [self _openRemoteFile:path withFlags:LIBSSH2_FXF_READ mode:0];
}

-(SFTPFile*)openRemoteFileForWrite:(NSString*)path
{
    return [self _openRemoteFile:path withFlags:LIBSSH2_FXF_WRITE|LIBSSH2_FXF_CREAT|LIBSSH2_FXF_APPEND 
			    mode:0666];
}

-(SFTPFileAttributes*)statRemoteFile:(NSString*)path
{
    if (mySession)
    {	
	LIBSSH2_SFTP_ATTRIBUTES attributes;
	[[SSHConnection sshLock] lock];
	int status = libssh2_sftp_stat(mySession, (char*)[path UTF8String], &attributes);
	[[SSHConnection sshLock] unlock];
	
	if (status == 0)
	    return [[SFTPFileAttributes alloc] initWithAttributes:&attributes 
							 filename:[path lastPathComponent]];
	else
	    NSLog(@"Unable to stat remote file");
	    return nil;
    }
    return nil;
}

- (void)deleteFile:(NSString*)path
{
    if (mySession)
    {
	[[SSHConnection sshLock] lock];
	libssh2_sftp_unlink_ex(mySession, (char*)[path UTF8String], [path length]);
	[[SSHConnection sshLock] unlock];
    }
}

-(NSString*)canonicalizePath:(NSString*)path
{
    int status;
    NSString * result = nil;
    
    if (mySession)
    {	
	char name_buffer[FILENAME_MAX];
	[[SSHConnection sshLock] lock];
	status = libssh2_sftp_realpath(mySession, (char*)[path UTF8String], 
				       name_buffer, FILENAME_MAX);
	[[SSHConnection sshLock] unlock];
		
	if (status > 0)
	    result = [NSString stringWithUTF8String:name_buffer];
    }
    return result;
}

-(void)_raiseSFTPException
{
    unsigned long error_code = libssh2_sftp_last_error(mySession);
    
    NSString * message;
    
    switch (error_code) 
    {
	case LIBSSH2_FX_EOF:
	    message = NSLocalizedString(@"End of file error", @"Error message when we reach the end of a remote file unexpectedly");
	    break;
	case LIBSSH2_FX_NO_SUCH_FILE:
	    message = NSLocalizedString(@"No such file", @"Error message when we cannot find a remote file");
	    break;
	case LIBSSH2_FX_PERMISSION_DENIED:
	    message = NSLocalizedString(@"Permission denied", @"Error when we are denied access to a remote file");
	    break;
	default:
	    message = [NSString stringWithFormat:NSLocalizedString(@"Error accessing remote files (%d)", @"General error when accessing remote files"), error_code];
	    break;
    }
    
    NSException * exception;
    exception = [NSException exceptionWithName:NSLocalizedString(@"Network Operation Error", @"Title for dialogs that show error messages about failed network operations") 
					reason:message 
				      userInfo:nil];
    @throw exception;  
}

@end
