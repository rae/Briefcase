//
//  SSHConnection.m
//  Briefcase
//
//  Created by Michael Taylor on 08/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "HMCore.h"

#import "SSHConnection.h"

#import <UIKit/UIKit.h>
#import "SFTPSession.h"
#import "BCConnectionManager.h"
#import "KeychainItem.h"
#import "KeychainKeyPair.h"
#import "SSHChannelFile.h"
#import "HashManager.h"
#import "BlockingAlert.h"
#import "UIAlertView+Activity.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>

#define kMD5DigestLength 16

static NSString * kSSHKeyPairName = @"com.heymacsoftware.briefcase.pubkeyauth";
static NSString * kSSHKeyAutoInstall = @"SSH Key Auto Install";
static int kDefaultSSHKeySize = 2048;
NSString * kSSHKeyPairGenerationCompleted = @"SSH Key Generation Completed";

NSLock * theSshLock = nil;

LIBSSH2_DISCONNECT_FUNC(ssh_disconnect)
{
    SSHConnection * connection = (SSHConnection*)(*abstract);
    [connection _didDisconnect];
}

@interface SSHConnection (Private)

- (void)_raiseException:(NSString*)message;
- (void)_initiateConnection;
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
    HMLog(@"Initializing SSH Session: %p", mySession);
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
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    @try
    {
	[self _initiateConnection];
	
	if (myUsername && myPassword && myExpectedHash)
	    // Authenticate manually
	    [self performSelectorInBackground:@selector(_authenticateManually) withObject:nil];
	else
	    // Authenticate with keychain
	    [self performSelectorInBackground:@selector(_authenticateUsingKeychain) withObject:nil];
	
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
	
	[self performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:NO];
    }
    @finally {
	[pool drain];
    }
}    

- (void)_initiateConnection
{
    int status, sock, error_num, h_addr_index;
    
    // Get the socket
    if (myNetService)
    {
	HMLog(@"Connecting to net service host: %@ type: %@ domain: %@",
	      [myNetService hostName], [myNetService type], 
	      [myNetService domain]);
	
	if ([[myNetService addresses] count] == 0)
	    [self _raiseException:@"No address for network service"];
	
	// Get first address from service
	NSData * first_address_data = [[myNetService addresses] objectAtIndex:0];
	struct sockaddr * socket_address = (struct sockaddr*)[first_address_data bytes];
	
	// Create a socket
	sock = socket(socket_address->sa_family, SOCK_STREAM, 0);
	HMLog(@"Socket handle: %d", socket);
	
	if (sock == -1)
	    [self _raiseException:@"Could not create socket"];
	
	// Connect to the socket
	status = connect(sock, socket_address, [first_address_data length]);
	
	if (status == -1)
	{
	    HMLog(@"Socket connect error: %d %s", status, strerror(errno));
	    [self _raiseException:[NSString stringWithUTF8String:strerror(errno)]];
	}
	else
	{
	    HMLog(@"Socket connect succeeded");
	}
    }
    else
    {   
	struct sockaddr_in server;
	struct hostent * hp; 
	
	HMLog(@"Connecting to host %@ on port %d", myHostName, myPort);
	
	// Create a socket
	sock = socket(AF_INET, SOCK_STREAM, 0);
	if (sock == -1) 
	    [self _raiseException:@"Could not create socket"];
	else
	    HMLog(@"Socket handle: %d", sock);
	
	server.sin_family = AF_INET;
	hp = getipnodebyname([myHostName UTF8String], AF_INET, AI_DEFAULT, &error_num);
	if (hp == 0) 
	{
	    HMLog(@"Hostname address lookup failed: %s", 
		  strerror(error_num));
	    [self _raiseException:@"Unknown host"];
	}
	
	h_addr_index = 0;
	while (hp->h_addr_list[h_addr_index] != NULL) 
	{
	    bcopy(hp->h_addr_list[h_addr_index], &server.sin_addr, hp->h_length);
	    server.sin_port = htons(myPort);
	    
	    char * addr_str = addr2ascii(AF_INET, &server.sin_addr, 
					 sizeof(struct in_addr), NULL);
	    if (addr_str)
		HMLog(@"Address for %@: %s", myHostName, addr_str);
	    
	    
	    status = connect(sock, (struct sockaddr *) &server, sizeof (server));
	    if (status == -1) 
	    {
		if (hp->h_addr_list[++h_addr_index] != NULL) 
		    // Try next address
		    continue;
		
		HMLog(@"Socket connection failed");
		
		NSString * message;
		char buffer[1024];
		if (0 == strerror_r(errno, buffer, 1024))
		{
		    message = [NSString stringWithFormat:NSLocalizedString(@"Error connecting to \"%@\": %s",@"Message displayed to users when network connection to a host fails.  A system provided message is appended"),
			       myHostName, buffer];
		    HMLog(@"Socket connection error: %s", buffer);
		}
		else
		    message = [NSString stringWithFormat:NSLocalizedString(@"Error connecting to \"%@\"",@"Message displayed to users when network connection to a host fails"),
			       myHostName];
		
		freehostent(hp);
		[self _raiseException:message];
	    }
	    else {
		HMLog(@"Socket connection successful");
	    }
	    
	    break;
	}
	
	freehostent(hp);
    }
    
    
    // Startup SSH
    [[SSHConnection sshLock] lock];
    HMLog(@"Starting up SSH session");
    status = libssh2_session_startup(mySession, sock);
    [[SSHConnection sshLock] unlock];
    if (status == -1)
    {
	HMLog(@"Failed to start SSH session with error code: %d", status);
	[self _raiseException:NSLocalizedString(@"Failed to establish SSH connection",@"Message when Briefcase cannot establish an SSH connection")];
    }
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
    
    HMLog(@"SSH authenticating manually");
    
    [[SSHConnection sshLock] lock];
    const char * hash = libssh2_hostkey_hash(mySession, LIBSSH2_HOSTKEY_HASH_MD5);
    [[SSHConnection sshLock] unlock];
    if(hash)
    {
        HMLog(@"Host hash: %s", hash);
        
	NSData * data = [NSData dataWithBytes:(const void *)hash length:kMD5DigestLength];
	if (![data isEqualToData:myExpectedHash])
	{
	    // If this is another Briefcase, then we should have 
	    // gotten our expected hash...bail
	    [self notifyFailure];
	    return;
	}
	
	int result = -1;
	
	if ([SSHConnection hasSSHKeyPair])
	{
	    // Try to authenticate using public/private key pair
	    [[SSHConnection sshLock] lock];
	    HMLog(@"Authenticating with public/private key pair");
	    KeychainKeyPair * pair = [SSHConnection sshKeyPair];
	    result = libssh2_userauth_publickey_fromfile(
					     mySession,
					     (char*)[self.username UTF8String],
					     (char*)[pair.publicKeyPath UTF8String],
					     (char*)[pair.privateKeyPath UTF8String],
					     NULL);
	    [[SSHConnection sshLock] unlock];
	    
	    if (result < 0)
	    {
		// We have to reconnect before we can try a different auth
		// method
		libssh2_session_disconnect(mySession,
					   "Normal Shutdown, Thank you for playing");
		libssh2_session_free(mySession);
		[self _initiateConnection];
	    }
	}
	
	if (result != 0)
	{
	    // Try password authentication
	    [[SSHConnection sshLock] lock];
	    HMLog(@"Authenticating with username and password: %@", self.username);
	    result = libssh2_userauth_password(mySession, 
					       (char*)[self.username UTF8String], 
					       (char*)[self.password UTF8String]);
	    [[SSHConnection sshLock] unlock];
	}
	
	if (result == 0) 
	{
            HMLog(@"Authentication successful");
            
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
            HMLog(@"Failed to authenticate with error code: %d", result);
	    [self performSelectorOnMainThread:@selector(notifyFailure) 
				   withObject:self 
				waitUntilDone:NO];
	}
    }
    else
        HMLog(@"Retrieving hash failed");
    
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
    int result = -1;
    
    HMLog(@"Authenticating using keychain");
    
    // Check the hash from the host to make sure
    // nobody is tricking our password out of us
    [[SSHConnection sshLock] lock];
    const char * hash = libssh2_hostkey_hash(mySession, LIBSSH2_HOSTKEY_HASH_MD5);
    [[SSHConnection sshLock] unlock];
    if(hash)
    {
        HMLog(@"Host hash: %s", hash);
        
	NSData * data = [NSData dataWithBytes:(const void *)hash length:kMD5DigestLength];
	
	if (![HashManager hashForHost:myHostName])
	{
	    // This is a new host hash.  Store it.
	    [HashManager setHashForHost:myHostName hash:data];
            HMLog(@"Storing new hash value");
	}
	else if (![data isEqualToData:[HashManager hashForHost:myHostName]])
	{
            HMLog(@"Hash values for host has changed");
            
	    // This does not match our stored hash!  Warn the user
	    if (![myDelegate warnAboutChangedHash])
	    {
		[[SSHConnection sshLock] lock];
		libssh2_session_disconnect(mySession,"User cancelled due to changed hash");
                HMLog(@"User cancelled due to changed hash");
		[[SSHConnection sshLock] unlock];
		// TODO: Report the failure
		return;
	    }
	    // Update keychain with new hash value
	    
	    [HashManager setHashForHost:myHostName hash:data];
            HMLog(@"Updated hash value for host");
	}
	
	myExpectedHash = [data retain];
    }    
    else
        HMLog(@"Retrieving hash failed");
    
    if ([SSHConnection hasSSHKeyPair])
    {
	// Try to authenticate using public/private key pair
	[[SSHConnection sshLock] lock];
	HMLog(@"Authenticating with public/private key pair");
	KeychainKeyPair * pair = [SSHConnection sshKeyPair];
	result = libssh2_userauth_publickey_fromfile(
						     mySession,
						     (char*)[self.username UTF8String],
						     (char*)[pair.publicKeyPath UTF8String],
						     (char*)[pair.privateKeyPath UTF8String],
						     NULL);
	[[SSHConnection sshLock] unlock];
    }
    
    if (result != 0)
    {
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
    }
    
    [pool release];
}

static NSString * theInteractivePassword = nil;

void interactiveAuthCallback(const char *name, int name_len, 
			     const char *instruction, int instruction_len, 
			     int num_prompts, 
			     const LIBSSH2_USERAUTH_KBDINT_PROMPT *prompts, 
			     LIBSSH2_USERAUTH_KBDINT_RESPONSE *responses, 
			     void **abstract)
{
    HMLog(@"Interactive authorization callback");
    
    for (int i = 0; i < num_prompts; i++)
    {
	if (theInteractivePassword && 
	    prompts[i].length >= 8 && 
	    0 == strncasecmp(prompts[i].text, "password", 8))
	{
            HMLog(@"Read password");
	    // This is a password prompt
	    responses[i].text = strdup((char*)[theInteractivePassword UTF8String]);
	    responses[i].length = [theInteractivePassword lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	}
	else {
	    NSString * prompt_string = [[NSString alloc] initWithBytes:prompts[i].text
								length:prompts[i].length
							      encoding:NSUTF8StringEncoding];
	    HMLog(@"Unknown Prompt: %@\n", prompt_string);
	    responses[i].length = 0;
	}
    }
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
    
    HMLog(@"Logging in with keychain item");
    
    // Try a simple password authentication
    
    [[SSHConnection sshLock] lock];
    int result = libssh2_userauth_password(mySession, 
					   (char*)[item.username UTF8String], 
					   (char*)[item.password UTF8String]);
    [[SSHConnection sshLock] unlock];
    
    if (result != 0)
    {
	int error_code = libssh2_session_last_error(mySession, NULL, NULL, 0);
	HMLog(@"Code: %d", error_code);
	
	// Try interactive keyboard authentication
	[[SSHConnection sshLock] lock];
	theInteractivePassword = item.password;
	result = libssh2_userauth_keyboard_interactive(mySession,
						       (char*)[item.username UTF8String],
						       interactiveAuthCallback);
	theInteractivePassword = nil;
	[[SSHConnection sshLock] unlock];
    }
    
    if (result == 0)
    {
        HMLog(@"Authentication for user %@ succeeded", item.username);
        
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
        HMLog(@"Authentication for user %@ failed", item.username);
        
	int error_code = libssh2_session_last_error(mySession, NULL, NULL, 0);
	
	HMLog(@"Authentication failure code: %d", error_code);
	
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
    //    HMAssert([NSThread isMainThread],@"Must call on main thread");
    
    if (mySession)
    {	
        HMLog(@"Disconnecting SSH session");
        
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
    {
	mySFTPSession = [[SFTPSession alloc] initWithConnection:self];
        if (mySFTPSession)
            HMLog(@"Initialized new SFTP connection");
        else
            HMLog(@"Failed to initialize new SFTP connection");
    }
    
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
    
    HMLog(@"Executing remote SSH command: %@ and file: %@", command, path);
    
    LIBSSH2_CHANNEL * ssh_channel = [self _newChannel];
    HMLog(@"Opening SSH channel: %p", ssh_channel);
    
    @try {
	[[SSHConnection sshLock] lock];
        HMLog(@"Performing SSH channel exec");
	status = libssh2_channel_exec(ssh_channel, (char*)[command UTF8String]);
	[[SSHConnection sshLock] unlock];
	
	if (0 == status)
	{
            HMLog(@"Channel exec succeeded");
            
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
        {
            HMLog(@"Channel exec failed");
	    [self _raiseException:NSLocalizedString(@"Unable to run command on remote host", @"Error message when remote command execution fails")];
        }
    }
    @finally 
    {
	if (ssh_channel)
	{
	    [[SSHConnection sshLock] lock];
            HMLog(@"Freeing SSH channel: %p", ssh_channel);
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
    
    HMLog(@"Executing SSH command with data: %@", command);
    
    LIBSSH2_CHANNEL * ssh_channel = [self _newChannel];
    HMLog(@"Opening SSH channel: %p", ssh_channel);
    
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
            HMLog(@"Freeing SSH channel: %p", ssh_channel);
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

#pragma mark SSH Key Management

+ (BOOL)hasSSHKeyPair
{
    return [KeychainKeyPair existsPairWithName:kSSHKeyPairName];
}

+ (void)ensureSSHKeyPairCreated
{
    
    if (![KeychainKeyPair existsPairWithName:kSSHKeyPairName])
        [self regenerateSSHKeyPair];
}

+ (void)_notifySSHRegenerationComplete:(KeychainKeyPair*)pair
{
    NSNotificationCenter * center;
    center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kSSHKeyPairGenerationCompleted
                          object:pair];    
}

#if 1

+ (void)_regenerateSSHKeyPairInBackground
{
    KeychainKeyPair * pair;
    pair = [[[KeychainKeyPair alloc] initWithName:kSSHKeyPairName
                                          keySize:kDefaultSSHKeySize] autorelease];
    [self performSelectorOnMainThread:@selector(_notifySSHRegenerationComplete:) 
                           withObject:pair waitUntilDone:YES];
    
}
+ (void)regenerateSSHKeyPair
{
    // Generate a new public key
    [KeychainKeyPair deletePairWithName:kSSHKeyPairName];
    [UIAlertView showBusyAlertWith:NSLocalizedString(@"Key Pair",@"Title for dialog that says were generating a public/private key pair")
                           message:NSLocalizedString(@"Generating public/private key pair", @"Message for dialog that says were generating a public/private key pair")
                         forTarget:self 
                      withSelector:@selector(_regenerateSSHKeyPairInBackground)];    
}

#else 

+ (void)regenerateSSHKeyPair
{
    // Generate a new public key
    [KeychainKeyPair deletePairWithName:kSSHKeyPairName];
    [UIAlertView showBusyAlertWith:NSLocalizedString(@"Key Pair",@"Title for dialog that says were generating a public/private key pair")
                           message:NSLocalizedString(@"Generating public/private key pair", @"Message for dialog that says were generating a public/private key pair")
                          forBlock:^(void) {
                              KeychainKeyPair * pair;
                              pair = [[[KeychainKeyPair alloc] initWithName:kSSHKeyPairName
                                                                    keySize:kDefaultSSHKeySize] autorelease];
                              [self performSelectorOnMainThread:@selector(_notifySSHRegenerationComplete:) 
                                                     withObject:pair waitUntilDone:YES];
                          }];    
}

#endif

+ (KeychainKeyPair*)sshKeyPair
{
    return [[[KeychainKeyPair alloc] initWithName:kSSHKeyPairName] autorelease];
}

+ (BOOL)autoInstallPublicKey
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:kSSHKeyAutoInstall];
}

+ (void)setAutoInstallPublicKey:(BOOL)auto_install
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:auto_install forKey:kSSHKeyAutoInstall];
}

@end
