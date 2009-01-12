//
//  SSHChannelFile.m
//  Briefcase
//
//  Created by Michael Taylor on 13/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SSHChannelFile.h"
#import "SSHConnection.h"

@implementation SSHChannelFile

- (id)initWithChannel:(LIBSSH2_CHANNEL*)channel
{
    self = [super init];
    if (self != nil) {
	myChannel = channel;
	
	[[SSHConnection sshLock] lock];
	myBuffer = [[NSMutableData alloc] initWithCapacity:libssh2_channel_window_read(channel)];
	[[SSHConnection sshLock] unlock];
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void)closeFile
{
    [[SSHConnection sshLock] lock];
    int result = libssh2_channel_send_eof(myChannel);
    [[SSHConnection sshLock] unlock];
    
    if (result != 0)
	[self _raiseException:NSLocalizedString(@"Unable to run command on remote host", @"Error message when remote command execution fails")];
}

- (void)writeData:(NSData*)data
{
    [[SSHConnection sshLock] lock];
    int result = libssh2_channel_write(myChannel, (void*)[data bytes], [data length]);
    [[SSHConnection sshLock] unlock];
    
    if (result <= 0)
	[self _raiseException:NSLocalizedString(@"Unable to run command on remote host", @"Error message when remote command execution fails")];
}

- (NSData*) readData
{
    NSData * result = nil;
    
    [[SSHConnection sshLock] lock];
    int read = libssh2_channel_read(myChannel, [myBuffer mutableBytes], [myBuffer length]);
    [[SSHConnection sshLock] unlock];
    
    if (read > 0)
	[myBuffer setLength:read];
    else 
    {
	[self _raiseException:NSLocalizedString(@"Unable to run command on remote host", @"Error message when remote command execution fails")];
    }
    return result;
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
