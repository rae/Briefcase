//
//  BriefcaseServer.m
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <Security/Security.h>

#import "BriefcaseServer.h"

#import "AsyncSocket.h"
#import "BriefcaseConnection.h"
#import "BlockingAlert.h"
#import "WorkerThread.h"
#import "FreeSpaceController.h"
#import "BriefcaseDownloadOperation.h"
#import "NetworkOperationQueue.h"
#import "KeychainKeyPair.h"
#import "NSData+Sec.h"
#import "SSCrypto.h"

static BriefcaseServer * theBriefcaseServer = nil;

@interface BriefcaseServer (Private)

- (void)_startServer;
- (void)_initializeKeys;

@end

@implementation BriefcaseServer

+ (BriefcaseServer*)sharedController
{
    if (!theBriefcaseServer)
	theBriefcaseServer = [[BriefcaseServer alloc] init];
    return theBriefcaseServer;
}

- (id) init
{
    self = [super init];
    if (self != nil)
    {
	myListenSocket = [[AsyncSocket alloc] initWithDelegate:self];
	myDownloadsByChannelID = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [myListenSocket release];
    [myDownloadsByChannelID release];
        
    [super dealloc];
}


- (void)startServer
{
    // Make sure our worker thread is running
    WorkerThread * thread = [BriefcaseConnection briefcaseConnectionThread];
    
    // Advertise with Bonjour
    myNetService = [[NSNetService alloc] initWithDomain:@"local." 
						   type:@"_briefcase._tcp." 
						   name:[[UIDevice currentDevice] name] 
						   port:kBriefcaseServerPort];
    [myNetService scheduleInRunLoop:thread.runLoop forMode:NSDefaultRunLoopMode];
    [myNetService publish];
    
    [self performSelector:@selector(_startServer)
		 onThread:thread 
	       withObject:nil 
	    waitUntilDone:NO];
    
    [self performSelectorInBackground:@selector(_initializeKeys) withObject:nil];
}

-(void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    BriefcaseConnection * new_connection = [[BriefcaseConnection alloc] initWithSocket:newSocket];
    new_connection.delegate = self;
}

-(NSRunLoop *)onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket
{
    return [[BriefcaseConnection briefcaseConnectionThread] runLoop];
}

- (void)connectionReady:(BriefcaseConnection*)connection
{
    // A connection we accepted is now ready for use.  Look for the 
    // authentication request
    [connection listenForMessage];
}

- (void)messageReceived:(BriefcaseMessage*)message onConnection:(BriefcaseConnection*)connection
{
    if (message.type == kConnectionRequest)
    {
	if (connection.isAuthenticated)
	{
	    // Error, this connection has already been authenticated!!
	    connection.delegate = nil;
	    [connection disconnect];
	    return;
	}
	
	// Get the data from the message
	NSDictionary * data = [NSKeyedUnarchiver unarchiveObjectWithData:message.payloadData];
	
	if (!data)
	{
	    // Error, invalid payload!!
	    connection.delegate = nil;
	    [connection disconnect];
	    return;
	}
	    
	NSString * name = [data objectForKey:@"name"];
	NSData * public_key_data = [data objectForKey:@"public_key"];
	
	BlockingAlert * server_alert;
	
	NSString * message_format = NSLocalizedString(@"Do you wish to receive files from \"%@\"? (Quitting Briefcase will cancel transfer.) Accept files?", @"Message asking the user if they want to receive a transfer from another iPhone and advising them how to cancel the connection");
	
	
	server_alert = [[BlockingAlert alloc] initWithTitle:NSLocalizedString(@"Connection Request", @"Title for dialog asking user if they wish to accept a connection from another iPhone") 
						    message:[NSString stringWithFormat:message_format, name]
						   delegate:self 
					  cancelButtonTitle:NSLocalizedString(@"No", @"No, refuse connection")
					  otherButtonTitles:NSLocalizedString(@"Yes", @"Yes, accept connection"), nil];
	
	NSInteger answer = [server_alert showInMainThread];
	
	if (answer == 0)
	{
	    connection.delegate = nil;
	    [connection disconnect];
	}
	else
	{
	    connection.isAuthenticated = YES;
	    
	    BriefcaseMessage * accepted_message = [BriefcaseMessage messageWithType:kConnectionAllowed];
	    	    
	    NSData * session_key = [SSCrypto getKeyDataWithLength:32];
	    
	    accepted_message.payloadData = session_key;
	    if (public_key_data)
		[accepted_message encryptWithPublicKey:public_key_data];
	    	    
	    [connection sendMessage:accepted_message];
	    
	    // Assign the key after sending the message so that we
	    // don't double encrypt it
	    connection.sessionKey = session_key;
	    
//	    NSLog(@"Symmetric key - server %@", session_key);
	}
    }
    else
    {
	if (!connection.isAuthenticated)
	{
	    // Someone has tried to send a message when they are not
	    // authenticated.  Terminate with extreme prejudice
	    connection.delegate = nil;
	    [connection disconnect];
	    return;
	}
	
	switch (message.type) {
	    case kFreeSpaceRequest:
	    {
		long long free_space = [[FreeSpaceController sharedController] freeSpace];
		BriefcaseMessage * response = [BriefcaseMessage messageWithType:kFreeSpaceResponse];
		response.channelID = message.channelID;
		response.payloadNumber = [NSNumber numberWithLongLong:free_space];
		[connection sendMessage:response];
		break;
	    }
	    case kFileHeader:
	    {
		// Create a new download file operation
		NSDictionary * file_header = message.payloadDictionary;
		if (![BriefcaseDownloadOperation okToDownload:file_header])
		{
		    // We cannot recieve this file
		    BriefcaseMessage * response = [BriefcaseMessage messageWithType:kRequestDenied];
		    response.channelID = message.channelID;
		    [connection sendMessage:response];
		    break;
		}
		BriefcaseDownloadOperation * op;
		op = [[BriefcaseDownloadOperation alloc] initWithFileHeader:file_header];
		op.connection = connection;
		[op setQueuePriority:NSOperationQueuePriorityVeryHigh];
		[myDownloadsByChannelID setObject:op forKey:[NSNumber numberWithDouble:message.channelID]];
		[[NetworkOperationQueue sharedQueue] addOperation:op];
		
		// Send back a response
		BriefcaseMessage * response = [BriefcaseMessage messageWithType:kFileHeaderResponse];
		response.channelID = message.channelID;
		[connection sendMessage:response];
		break;
	    }
	    case kFileData:
	    {
		BriefcaseDownloadOperation * op;
		op = [myDownloadsByChannelID objectForKey:[NSNumber numberWithDouble:message.channelID]];
		if (op)
		{
		    enum BriefcaseMessageType response_type;
		    
		    if (op.isCancelled)
			response_type = kFileCancelled;
		    else
			response_type = kFileDataResponse;
		    
		    // Send back a response
		    BriefcaseMessage * response = [BriefcaseMessage messageWithType:response_type];
		    response.channelID = message.channelID;
		    [connection sendMessage:response];
		    
		    if (!op.isCancelled)
			[op addData:message.payloadData]; 
		}
		else
		{
		    // Invalid file data message, terminate connection
		    connection.delegate = nil;
		    [connection disconnect];
		    return;		    
		}
		break;
	    }
	    case kFileDone:
	    {
		BriefcaseDownloadOperation * op;
		NSNumber * channelID = [NSNumber numberWithDouble:message.channelID];
		op = [myDownloadsByChannelID objectForKey:channelID];
		if (op)
		{
		    [op done]; 
		    
		    // Send back a response
		    BriefcaseMessage * response = [BriefcaseMessage messageWithType:kFileDoneResponse];
		    response.channelID = message.channelID;
		    [connection sendMessage:response];
		    
		    [myDownloadsByChannelID removeObjectForKey:channelID];
		}
		else
		{
		    // Invalid file data message, terminate connection
		    connection.delegate = nil;
		    [connection disconnect];
		    return;		    
		}
		break;
	    }
	    case kFileCancelled:
	    {
		BriefcaseDownloadOperation * op;
		NSNumber * channelID = [NSNumber numberWithDouble:message.channelID];
		op = [myDownloadsByChannelID objectForKey:channelID];
		if (op)
		{
		    // Call done to allow the user to keep part of the file
		    // if they want..
		    [op done]; 
		    
		    // Send back a response
		    BriefcaseMessage * response = [BriefcaseMessage messageWithType:kFileCancelledResponse];
		    response.channelID = message.channelID;
		    [connection sendMessage:response];
		    
		    [myDownloadsByChannelID removeObjectForKey:channelID];
		}
		else
		{
		    // Invalid file data message, terminate connection
		    connection.delegate = nil;
		    [connection disconnect];
		    return;		    
		}
		break;
		
	    }
	    default:
		connection.delegate = nil;
		[connection disconnect];
		return;
		break;
	}
    }
    
    // If all is good, listen for the next message
    [connection listenForMessage];
}

#pragma mark ConnectionDelegate methods

- (void)connectionEstablished:(Connection*)connection
{
    
}

- (void)connectionTerminated:(Connection*)connection
{
    for (NSNumber * key in myDownloadsByChannelID)
    {
	BriefcaseDownloadOperation * op = [myDownloadsByChannelID objectForKey:key];
	if (![op isFinished])
	{
	    [op done];
	    [op cancel];
	}
	[myDownloadsByChannelID removeObjectForKey:key];
    }
}

- (void)connectionFailed:(Connection*)connection
{
    
}

- (int)allowConnectionToHost:(NSString*)host withHash:(NSData*)hash
{
    return 0;
}

- (BOOL)warnAboutChangedHash
{
    NSAssert(FALSE,@"Should not be called");
    return NO;
}

- (void)displayLoginFailed
{
    
}

- (void)requestUsernameAndPassword:(KeychainItem*)item 
			    target:(id)object 
		   successSelector:(SEL)success_selector
		 cancelledSelector:(SEL)cancelled_selector
		      errorMessage:(NSString*)error_message
{
    
}

@end
    
@implementation BriefcaseServer (Private)

- (void)_startServer
{
    // Start listening
    NSError *error = nil;
    if(![myListenSocket acceptOnPort:kBriefcaseServerPort error:&error])
    {
	NSString * format = NSLocalizedString(@"Briefcase server failed to start: %@", "Message to user when starting the server fails");
	
	UIAlertView * server_alert;
	server_alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Server Error", @"Title for dialog telling the user that the server failed to start") 
						  message:[NSString stringWithFormat:format, [error localizedFailureReason]]
						 delegate:self 
					cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button")
					otherButtonTitles:nil];
	
	[server_alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
	[server_alert release];
	return;
    }
}


- (void)_initializeKeys
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    myKeychainPair = [BriefcaseConnection briefcaseKeyPair];

#if 0
    
    NSData * session_key = [SSCrypto getKeyDataWithLength:32];
    
    NSLog(@"Size of session key %d", [session_key length]);
    
    NSData * encrypted = [session_key encryptWithPublicKey:myKeychainPair.publicKey];
    
    NSData * decrypted = [encrypted decryptWithPrivateKey:myKeychainPair.privateKey];
    
    NSAssert([decrypted isEqualToData:session_key],@"Failed to get back key");
    
    NSData * stuff = [SSCrypto getKeyDataWithLength:102400];
    
    encrypted = [stuff encryptWithSymmetricKey:session_key];
    
    decrypted = [encrypted decryptWithSymmetricKey:session_key];
    
    NSLog(@"Size of encrypted data %d", [encrypted length]);
    
    NSAssert([stuff isEqualToData:decrypted],@"Failed to get back data");
    
#endif

    [pool release];
}



@end
