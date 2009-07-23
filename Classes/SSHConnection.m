//
//  SSHConnection.m
//  Briefcase
//
//  Created by Michael Taylor on 08/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "HeyMac.h"

#import "SSHConnection.h"

#import <UIKit/UIKit.h>
#import "SFTPSession.h"
#import "ConnectionManager.h"
#import "KeychainItem.h"
#import "SSHChannelFile.h"
#import "HashManager.h"
#import "BlockingAlert.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#define kMD5DigestLength 16

NSLock * theSshLock = nil;

LIBSSH2_DISCONNECT_FUNC(ssh_disconnect)
{
    SSHConnection * connection = (SSHConnection*)(*abstract);
    [connection _didDisconnect];
}

@interface SSHConnection (Private)

- (void)_raiseException:(NSString*)message;
- (void)_connect;
- (void)_didDisconnect;
- (LIBSSH2_CHANNEL*)_newChannel;
- (void)performRequestUsernameAndPassword;

@end


@implementation SSHConnection 

@synthesize expectedHash = myExpectedHash;
@synthesize session = mySession;

+ (NSLock*)sshLock
{
    if (!theSshLock)
    {
	theSshLock = [[NSLock alloc] init];
    }
    return theSshLock;
}

-(NSString*)protocol
{
    return kSSHProtocol;
}

-(void)dealloc
{
    [mySFTPSession release];
    if (self.isConnected)
	[self disconnect];
    [myUserData release];
    //[myExpectedHash release];
    [super dealloc];
}

-(BOOL)connect
//
// Initiate an SSH connections
//
// Thread: main
// 
{
    HMAssert([NSThread isMainThread],@"Must call on main thread");
    
    [[SSHConnection sshLock] lock];
    mySession = libssh2_session_init();
    [[SSHConnection sshLock] unlock];
        
    [self performSelectorInBackground:@selector(_connect) withObject:nil];
    
    return TRUE;
}

- (BOOL)isConnected
{
    return mySession != NULL;
}

- (void)_connect
//
// Establish the socket connection and start the SSH session. Then 
// trigger the authentication process
//
// Thread: background
//
{
    int status, sock, error_num, h_addr_index;
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    @try
    {
	// Get the socket
	if (myNetService)
	{
	    if ([[myNetService addresses] count] == 0)
		[self _raiseException:@"No address for network service"];
	    
	    // Get first address from service
	    NSData * first_address_data = [[myNetService addresses] objectAtIndex:0];
	    struct sockaddr * socket_address = (struct sockaddr*)[first_address_data bytes];
	    
	    // Create a socket
	    sock = socket(socket_address->sa_family, SOCK_STREAM, 0);
	    if (sock == -1)
		[self _raiseException:@"Could not create socket"];
	    
	    // Connect to the socket
	    status = connect(sock, socket_address, [first_address_data length]);
	    if (status == -1)
		[self _raiseException:[NSString stringWithUTF8String:strerror(errno)]];
	}
	else
	{   
	    struct sockaddr_in server;
	    struct hostent * hp; 
	    
	    // Create a socket
	    sock = socket(AF_INET, SOCK_STREAM, 0);
	    if (sock == -1)
		[self _raiseException:@"Could not create socket"];
	    
	    server.sin_family = AF_INET;
	    hp = getipnodebyname([myHostName UTF8String], AF_INET, AI_DEFAULT, &error_num);
	    if (hp == 0) 
		[self _raiseException:@"Unknown host"];
	    
	    h_addr_index = 0;
	    while (hp->h_addr_list[h_addr_index] != NULL) 
	    {
		bcopy(hp->h_addr_list[h_addr_index], &server.sin_addr, hp->h_length);
		server.sin_port = htons(myPort);
		status = connect(sock, (struct sockaddr *) &server, sizeof (server));
		if (status == -1) 
		{
		    if (hp->h_addr_list[++h_addr_index] != NULL) 
			// Try next address
			continue;
		    
		    NSString * message;
		    char buffer[1024];
		    if (0 == strerror_r(errno, buffer, 1024))
			message = [NSString stringWithFormat:NSLocalizedString(@"Error connecting to \"%@\": %s",@"Message displayed to users when network connection to a host fails.  A system provided message is appended"),
				   myHostName, buffer];
		    else
			message = [NSString stringWithFormat:NSLocalizedString(@"Error connecting to \"%@\"",@"Message displayed to users when network connection to a host fails"),
				   myHostName];
		    
		    freehostent(hp);
		    [self _raiseException:message];
		}
		break;
	    }
	    
	    freehostent(hp);
	}
	
	
	// Startup SSH
	[[SSHConnection sshLock] lock];
	status = libssh2_session_startup(mySession, sock);
	[[SSHConnection sshLock] unlock];
	if (status == -1)
	    [self _raiseException:NSLocalizedString(@"Failed to establish SSH connection",@"Message when Briefcase cannot establish an SSH connection")];
	
    }    
    @catch (NSException * e) 
    {
	BlockingAlert * alert;
	alert = [[BlockingAlert alloc] initWithTitle:NSLocalizedString(@"Network Operation Error", @"Title for dialogs that show error messages about failed network operations")
					     message:[e reason] 
					    delegate:nil
				   cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button")
				   otherButtonTitles:nil];
	[alert showInMainThread];
    }
            
    if (myUsername && myPassword && myExpectedHash)
	// Authenticate manually
	[self performSelectorInBackground:@selector(_authenticateManually) withObject:nil];
    else
	// Authenticate with keychain
	[self performSelectorInBackground:@selector(_authenticateUsingKeychain) withObject:nil];
    
    [pool drain];
}    
    
- (void)_authenticateManually
//
// Authenticate using a given a specific username and password.
//
// Thread: background
//
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    // Authenticate using our stored username, password, and hash
    
    [[SSHConnection sshLock] lock];
    const char * hash = libssh2_hostkey_hash(mySession, LIBSSH2_HOSTKEY_HASH_MD5);
    [[SSHConnection sshLock] unlock];
    if(hash)
    {
	NSData * data = [NSData dataWithBytes:(const void *)hash length:kMD5DigestLength];
	if (![data isEqualToData:myExpectedHash])
	{
	    // If this is another Briefcase, then we should have 
	    // gotten our expected hash...bail
	    [self notifyFailure];
	    return;
	}
	
	[[SSHConnection sshLock] lock];
	int result = libssh2_userauth_password(mySession, 
					       (char*)[self.username UTF8String], 
					       (char*)[self.password UTF8String]);
	[[SSHConnection sshLock] unlock];
		
	NSNotificationCenter * notification_center = [NSNotificationCenter defaultCenter];

	if (result == 0) 
	{
	    if (myDelegate)
	    {
		// Inform the delegate
		[(NSObject*)myDelegate performSelectorOnMainThread:@selector(connectionEstablished:)
							withObject:self
						     waitUntilDone:YES];
	    }
	    
	    // Also notify any observers
	    [self performSelectorOnMainThread:@selector(notifyConnected) withObject:nil waitUntilDone:NO];
	}
	else
	{
	    [self performSelectorOnMainThread:@selector(notifyFailure) 
				   withObject:self 
				waitUntilDone:NO];
	}
    }
    
    [pool drain];
}

- (void)_authenticateUsingKeychain
//
// Authenticate using the given keychain item
//
// Thread: background
//
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    // Check the hash from the host to make sure
    // nobody is tricking our password out of us
    [[SSHConnection sshLock] lock];
    const char * hash = libssh2_hostkey_hash(mySession, LIBSSH2_HOSTKEY_HASH_MD5);
    [[SSHConnection sshLock] unlock];
    if(hash)
    {
	NSData * data = [NSData dataWithBytes:(const void *)hash length:kMD5DigestLength];
	
	if (![HashManager hashForHost:myHostName])
	{
	    // This is a new host hash.  Store it.
	    [HashManager setHashForHost:myHostName hash:data];
	}
	else if (![data isEqualToData:[HashManager hashForHost:myHostName]])
	{
	    // This does not match our stored hash!  Warn the user
	    if (![myDelegate warnAboutChangedHash])
	    {
		[[SSHConnection sshLock] lock];
		libssh2_session_disconnect(mySession,"User cancelled due to changed hash");
		[[SSHConnection sshLock] unlock];
		// TODO: Report the failure
		return;
	    }
	    // Update keychain with new hash value
	    
	    [HashManager setHashForHost:myHostName hash:data];
	}
	
	myExpectedHash = [data retain];
    }    
    
    // Try to find a username, password, and hash
    KeychainItem * keychain_item;
    keychain_item = [KeychainItem findOrCreateItemForHost:myHostName 
						   onPort:myPort 
						 protocol:kSSHProtocol
						 username:myUsername];
    
    //    [keychain_item dump];
    
    NSAssert(keychain_item,@"Unable to create keychain item!");
    // TODO: Report the failure
    if (!keychain_item) return;
    
    if ([keychain_item.username length] > 0 && [keychain_item.password length] > 0)
	// We have a username and password.  Try to log in
	[self performSelectorOnMainThread:@selector(loginWithKeychainItem:)
			       withObject:[keychain_item retain] 
			    waitUntilDone:YES];
    else
    {
	// Call requestUsernameAndPassword on the main thread
	[self performSelectorOnMainThread:@selector(performRequestUsernameAndPassword:)
			       withObject:keychain_item
			    waitUntilDone:YES];
    }

    [pool release];
}


-(void)loginWithKeychainItem:(KeychainItem*)item
//
// Attempt a login with the given keychain item. Ask the user for 
// a new username and password if it fails
//
// Thread: main
//
{        
    HMAssert([NSThread isMainThread],@"Must call on main thread");
    
    [[SSHConnection sshLock] lock];
    int result = libssh2_userauth_password(mySession, 
					   (char*)[item.username UTF8String], 
					   (char*)[item.password UTF8String]);
    
    [[SSHConnection sshLock] unlock];
    
    if (result == 0)
    {
	// Save the successfull username and password so that 
	// we can reauthenticate as needed
	myUsername = [item.username retain];
	myPassword = [item.password retain];
	
	if (myDelegate)
	    [myDelegate connectionEstablished:self];
	
	// Also notify any observers
	NSNotificationCenter * notification_center = [NSNotificationCenter defaultCenter];
	[notification_center postNotificationName:kConnectionEstablished object:self];
    }
    else
    {
	int error_code = libssh2_session_last_error(mySession, NULL, NULL, 0);
	
	HMLog(@"Code: %d", error_code);
	
	[self performSelector:@selector(_retryLogin:) withObject:item afterDelay:0.1];
    }
    
    [item release];
}

-(void)_retryLogin:(KeychainItem*)item
{
    [self requestUsernameAndPassword:[item retain]
			      target:self 
		     successSelector:@selector(loginWithKeychainItem:) 
		   cancelledSelector:@selector(disconnect)
			errorMessage:NSLocalizedString(@"Authentication Failed",@"Message displayed to the user when the username/password is incorrect")];
}

-(void)disconnect
//
// Disconnect this SSH connection
//
// Thread: main
//
{
    HMAssert([NSThread isMainThread],@"Must call on main thread");
    
    if (mySession)
    {	
	[[SSHConnection sshLock] lock];
	libssh2_session_disconnect(mySession,"Disconnect requested by user");
	[[SSHConnection sshLock] unlock];
		
	mySession = nil;
	
	[myUserData release];
	myUserData = nil;
    }
    
    // Also notify any observers
    NSNotificationCenter * notification_center = [NSNotificationCenter defaultCenter];
    [notification_center postNotificationName:kConnectionTerminated object:self];
    
    // This must go last as it will delete this object
    [myDelegate connectionTerminated:self];
}

-(SFTPSession*)getSFTPSession
{
    if (mySession && !mySFTPSession) 
	mySFTPSession = [[SFTPSession alloc] initWithConnection:self];
    
    return mySFTPSession;
}

-(NSData*)executeCommand:(NSString*)command
{
    return [self executeCommand:command withInput:nil];
}

-(NSData*)executeCommand:(NSString*)command withInputFile:(NSString*)path
{
    NSData * result = nil;
    char * buffer = NULL;
    int status;
    
    LIBSSH2_CHANNEL * ssh_channel = [self _newChannel];
        
    @try {
	[[SSHConnection sshLock] lock];
	status = libssh2_channel_exec(ssh_channel, (char*)[command UTF8String]);
	[[SSHConnection sshLock] unlock];
	
	if (0 == status)
	{
	    NSFileHandle * handle = [NSFileHandle fileHandleForReadingAtPath:path];
	    
	    [[SSHConnection sshLock] lock];
	    unsigned int write_size = libssh2_channel_window_write(ssh_channel);
	    [[SSHConnection sshLock] unlock];
	    
	    NSData * file_data = [handle readDataOfLength:write_size];
	    while ([file_data length] > 0) 
	    {
		int write_result;
		[[SSHConnection sshLock] lock];
		write_result = libssh2_channel_write(ssh_channel, (void*)[file_data bytes], [file_data length]);
		[[SSHConnection sshLock] unlock];

		if (write_result <= 0)
		    [self _raiseException:NSLocalizedString(@"An error was encountered while executing the remote command", @"Error message when remote command execution fails")];

		file_data = [handle readDataOfLength:write_size];
	    }
	    [[SSHConnection sshLock] lock];
	    status = libssh2_channel_send_eof(ssh_channel);
	    [[SSHConnection sshLock] unlock];
	    if (status != 0)
		[self _raiseException:NSLocalizedString(@"An error was encountered while executing the remote command", @"Error message when remote command execution fails")];
	    
	    [[SSHConnection sshLock] lock];
	    unsigned int window_size = libssh2_channel_window_read(ssh_channel);
	    [[SSHConnection sshLock] unlock];
	    
	    NSMutableData * data = [[NSMutableData alloc] initWithCapacity:window_size];
	    buffer = (char*)malloc(window_size);
	    while (TRUE) {
		[[SSHConnection sshLock] lock];
		int read = libssh2_channel_read(ssh_channel, buffer, window_size);
		[[SSHConnection sshLock] unlock];
		if (read > 0)
		    [data appendBytes:buffer length:read];
		else if	(read == 0)
		{
		    result = [data autorelease];;
		    break;
		}
		else
		{
		    [data release];
		    [self _raiseException:NSLocalizedString(@"An error was encountered while executing the remote command", @"Error message when remote command execution fails")];
		}
	    }
	}
	else
	    [self _raiseException:NSLocalizedString(@"Unable to run command on remote host", @"Error message when remote command execution fails")];
    }
    @finally 
    {
	if (ssh_channel)
	{
	    [[SSHConnection sshLock] lock];
	    libssh2_channel_free(ssh_channel);
	    [[SSHConnection sshLock] unlock];
	}
	if (buffer)
	    free(buffer);
    }
        
    return result;
}

- (NSData*)executeCommand:(NSString*)command withInput:(NSData*)input;
{
    NSData * result = nil;  
    char * buffer = NULL;
    int status;

    LIBSSH2_CHANNEL * ssh_channel = [self _newChannel];;
            
    @try {
	[[SSHConnection sshLock] lock];
	status = libssh2_channel_exec(ssh_channel, (char*)[command UTF8String]);
	[[SSHConnection sshLock] unlock];
	if (0 == status)
	{
	    // Write input to channel
	    if (input)
	    {
		int write_result;
		[[SSHConnection sshLock] lock];
		write_result = libssh2_channel_write(ssh_channel, 
						     (void*)[input bytes], 
						     [input length]);
		[[SSHConnection sshLock] unlock];
		
		if (write_result <= 0)
		    [self _raiseException:NSLocalizedString(@"An error was encountered while executing the remote command", @"Error message when remote command execution fails")];
		
		status = libssh2_channel_send_eof(ssh_channel);
		if (status != 0)
		    [self _raiseException:NSLocalizedString(@"An error was encountered while executing the remote command", @"Error message when remote command execution fails")];
	    }
	    
	    [[SSHConnection sshLock] lock];
	    unsigned int window_size = libssh2_channel_window_read(ssh_channel);
	    [[SSHConnection sshLock] unlock];

	    NSMutableData * data = [[NSMutableData alloc] initWithCapacity:window_size];
	    buffer = (char*)malloc(window_size);
	    while (TRUE) {
		[[SSHConnection sshLock] lock];
		int read = libssh2_channel_read(ssh_channel, buffer, window_size);
		[[SSHConnection sshLock] unlock];
		if (read > 0)
		    [data appendBytes:buffer length:read];
		else if	(read == 0)
		{
		    result = [data autorelease];
		    break;
		}
		else
		    [self _raiseException:NSLocalizedString(@"An error was encountered while executing the remote command", @"Error message when remote command execution fails")];
	    }
	}
	else
	    [self _raiseException:NSLocalizedString(@"Unable to run command on remote host", @"Error message when remote command execution fails")];
    }
    @finally 
    {
	if (ssh_channel)
	{
	    [[SSHConnection sshLock] lock];
	    libssh2_channel_free(ssh_channel);
	    [[SSHConnection sshLock] unlock];
	}
	if (buffer)
	    free(buffer);
    }
    
    return result;
}

- (SSHChannelFile*)openExecChannelWithCommand:(NSString*)command
{
    int status;    
    
    LIBSSH2_CHANNEL * ssh_channel = [self _newChannel];
    
    [[SSHConnection sshLock] lock];
    status = libssh2_channel_exec(ssh_channel, (char*)[command UTF8String]);
    [[SSHConnection sshLock] unlock];
    
    if (0 == status)
	return [[[SSHChannelFile alloc] initWithChannel:ssh_channel] autorelease];
    else
	[self _raiseException:NSLocalizedString(@"Unable to run command on remote host", @"Error message when remote command execution fails")];
    
    return nil;
}

- (void)_raiseException:(NSString*)message
{
    if (!self.isConnected)
	[self performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:YES];
    
    NSException * exception;
    exception = [NSException exceptionWithName:NSLocalizedString(@"Network Operation Error", @"Title for dialogs that show error messages about failed network operations") 
					reason:message 
				      userInfo:nil];
    @throw exception;    
}

- (LIBSSH2_CHANNEL*)_newChannel
{
    [[SSHConnection sshLock] lock];
    LIBSSH2_CHANNEL * new_channel = libssh2_channel_open_session(mySession);
    [[SSHConnection sshLock] unlock];
    
    if (!new_channel)
	[self _raiseException:NSLocalizedString(@"Unable to run command on remote host", @"Error message when remote command execution fails")];
            
    return new_channel;
}

- (void)_didDisconnect
{
    mySession = nil;
}

- (void)performRequestUsernameAndPassword:(KeychainItem*)keychain_item
{
    [self requestUsernameAndPassword:[keychain_item retain]
			      target:self 
		     successSelector:@selector(loginWithKeychainItem:) 
		   cancelledSelector:@selector(disconnect)
			errorMessage:nil];
}

@end
