//
//  BriefcaseConnections.m
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BriefcaseConnection.h"
#import "AsyncSocket.h"
#import "WorkerThread.h"
#import "BriefcaseMessage.h"
#import "NSData+Sec.h"

#pragma mark Statics and Definitions

static NSTimeInterval kSocketWriteTimeout = -1.0;
static NSTimeInterval kSocketReadTimeout = -1.0;

static WorkerThread *	    theWorkerThread = nil;
static KeychainKeyPair *    theKeychainKeyPair = nil;

#pragma mark Private Method Declarations

@interface BriefcaseConnection (Private)

- (void)_connect;
- (void)_sendMessage:(BriefcaseMessage*)message;
- (void)_notifyDisconnect;
- (void)_notifyConnect;
- (void)_readMessageHeader:(BriefcaseMessage*)message;

@end

#pragma mark BriefcaseConnection Implementation

@implementation BriefcaseConnection

@synthesize isAuthenticated = myIsAuthenticated;
@synthesize sessionKey = mySessionKey;

+ (WorkerThread*)briefcaseConnectionThread
{
    if (!theWorkerThread)
    {
	theWorkerThread = [[WorkerThread alloc] init];
	[theWorkerThread start];
    }
    return theWorkerThread;
}

+ (KeychainKeyPair*)briefcaseKeyPair
{
    if (!theKeychainKeyPair)
    {
	@try 
	{
	    theKeychainKeyPair = [[KeychainKeyPair alloc] initWithName:@"com.heymacsoftware.briefcase"];
	}
	@catch(NSException * exception)
	{
	    NSLog(@"Exception caught\n  %@", exception);
	}
    }
    
    return theKeychainKeyPair;
}

- (id)initWithSocket:(AsyncSocket*)socket
{
    self = [super initWithHost:@"" port:0];
    if (self != nil) 
    {
	mySocket = [socket retain];
	[mySocket setDelegate:self];
	myMessagesByTag = [[NSMutableDictionary alloc] initWithCapacity:16];
	myChannelsByID = [[NSMutableDictionary alloc] initWithCapacity:8];
	myIsAuthenticated = NO;
	myIsInitiatingConnection = NO;
	
	myIsAwaitingHeader = NO;
	myQueuedHeaderReads = [[NSMutableArray alloc] initWithCapacity:8];
	
	mySessionKey = nil;
    }
    return self;
}

-(id)initWithHost:(NSString*)host 
	     port:(NSInteger)port
{
    self = [super initWithHost:host port:port];
    if (self != nil) 
    {
	myMessagesByTag = [[NSMutableDictionary alloc] initWithCapacity:16];
	myChannelsByID = [[NSMutableDictionary alloc] initWithCapacity:8];
	myIsAuthenticated = NO;
	myIsInitiatingConnection = NO;
	
	myIsAwaitingHeader = NO;
	myQueuedHeaderReads = [[NSMutableArray alloc] initWithCapacity:8];
	
	mySessionKey = nil;
    }
    return self;
}

- (void) dealloc
{
    if (mySocket)
	[mySocket setDelegate:nil];
    [mySocket release];
    [myMessagesByTag release];
    [super dealloc];
}

- (BOOL)connect
{
    [mySocket release];
    
    mySocket = [[AsyncSocket alloc] initWithDelegate:self];
    myIsInitiatingConnection = YES;
    
    [self performSelector:@selector(_connect) 
		 onThread:[BriefcaseConnection briefcaseConnectionThread] 
	       withObject:nil 
	    waitUntilDone:NO];
    
    return TRUE;
}

- (BriefcaseChannel*)openChannelWithDelegate:(id <BriefcaseChannelDelegate>)delegate;
{
    BriefcaseChannel * channel = [[BriefcaseChannel alloc] initWithConnection:self delegate:delegate];
    [myChannelsByID setObject:channel forKey:[NSNumber numberWithDouble:channel.channelID]];
    return [channel autorelease];
}

- (void)sendMessage:(BriefcaseMessage*)message
{    
    // Encrypt if need be
    if (message.payloadData && mySessionKey)
	[message encryptWithSymmetricKey:mySessionKey];
    
    [self performSelector:@selector(_sendMessage:) 
		 onThread:[BriefcaseConnection briefcaseConnectionThread] 
	       withObject:message 
	    waitUntilDone:NO];
}

- (void)listenForMessage
{
    BriefcaseMessage * message = [BriefcaseMessage messageWithType:kInvalidMessageType];
        
    NSNumber * tag_number = [NSNumber numberWithLong:message.tag];
    @synchronized(myMessagesByTag)
    {
	[myMessagesByTag setObject:message forKey:tag_number];
    }
    
    // Read the size and type
    message.transmitState = kReadingHeader;
    
    if ([NSThread currentThread] == [BriefcaseConnection briefcaseConnectionThread])
    {
	[self _readMessageHeader:message];
    }
    else
    {
	[self performSelector:@selector(_readMessageHeader:) 
		     onThread:[BriefcaseConnection briefcaseConnectionThread] 
		   withObject:message 
		waitUntilDone:NO];
    }
}

- (void)disconnect
{
    NSLog(@"Disconnecting");
    
    [mySocket disconnect];
    
    [self performSelectorOnMainThread:@selector(_notifyDisconnect) 
			   withObject:nil 
			waitUntilDone:YES];
}

#pragma mark AsyncSocket delegates

-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{	    
    if (myDelegate && [(NSObject*)myDelegate respondsToSelector:@selector(connectionReady:)])
	[(NSObject*)myDelegate performSelector:@selector(connectionReady:) 
				    withObject:self];
    
    if (myIsInitiatingConnection)
    {
	// We are trying to connect.  Ask for permission to send files
	BriefcaseMessage * message = [BriefcaseMessage messageWithType:kConnectionRequest];
	
	// Send our device name and our public key
	KeychainKeyPair * key_pair = [BriefcaseConnection briefcaseKeyPair];
	NSDictionary * data;
	data = [NSDictionary dictionaryWithObjectsAndKeys:
		[[UIDevice currentDevice] name], @"name",
		key_pair.publicKey, @"public_key",
		nil];
	
	message.payloadDictionary = data;
	
	[self _sendMessage:message];
    }
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    BriefcaseMessage * message;
    
    @synchronized(myMessagesByTag)
    {
	message = [myMessagesByTag objectForKey:[NSNumber numberWithLong:tag]];
    }
    
    NSAssert(message,@"No message found for tag!");
    
    if (message)
    {
	message.transmitError = nil;
	if (message.transmitCondition)
	    [message.transmitCondition signal];
	
	// If this is a connection request, look for the answer
	if (message.type == kConnectionRequest)
	    [self listenForMessage];
	
	@synchronized(myMessagesByTag)
	{
	    [myMessagesByTag removeObjectForKey:[NSNumber numberWithLong:tag]];
	}
    }
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    // Something went wrong.  Tell all the people sending messages
    
    @synchronized(myMessagesByTag)
    {
	for (BriefcaseMessage * message in [myMessagesByTag allValues])
	{
	    message.transmitError = err;
	    if (message.transmitCondition)
		[message.transmitCondition signal];
	}
	
	[myMessagesByTag removeAllObjects];
    }
    
    if (myIsAuthenticated)
    {
	[self performSelectorOnMainThread:@selector(_notifyDisconnect) 
			       withObject:nil 
			    waitUntilDone:YES];
    }
    else
    {
	[self performSelectorOnMainThread:@selector(_notifyFailure) 
			       withObject:nil 
			    waitUntilDone:YES];
    }
}

-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
    BriefcaseMessage * message;
    
    @synchronized(myMessagesByTag)
    {
	message = [myMessagesByTag objectForKey:[NSNumber numberWithLong:tag]];
    }
    
    if (message)
    {
	if (message.transmitState == kReadingHeader)
	{
	    // Extract the header and read the body
	    // Extract the type and size
	    if ([data length] != kHeaderDataSize)
	    {
		// Invalid message!  Abort connection
		[self disconnect];
		return;
	    }
	    message.headerData = data;
	    NSUInteger payload_size = [BriefcaseMessage payloadSizeFromHeader:data];
	    
	    if (payload_size > 0)
	    {
		// Reset the message to read the data
		message.transmitState = kReadingData;
		[mySocket readDataToLength:payload_size withTimeout:kSocketReadTimeout tag:message.tag];
	    }
	    else
	    {
		message.transmitState = kTransmissionComplete;
		message.payloadData = nil;
	    }
	    
	    myIsAwaitingHeader = NO;
	    if ([myQueuedHeaderReads count] > 0)
	    {
		[self _readMessageHeader:[myQueuedHeaderReads lastObject]];
		[myQueuedHeaderReads removeLastObject];
	    }
	}
	else
	{
	    message.payloadData = data;
	    if (message.payloadEncrypted && mySessionKey)
		[message decryptWithSymmetricKey:mySessionKey];
	    
	    message.transmitState = kTransmissionComplete;
	}
	
//	NSAssert(message.type==kConnectionAllowed||message.type==kConnectionRequest||message,@"Unknown message type");
	
	if (message.transmitState == kTransmissionComplete) 
	{
	    if (message.transmitCondition)
		[message.transmitCondition signal];
	    
	    if (myDelegate && [(NSObject*)myDelegate respondsToSelector:@selector(messageReceived:onConnection:)])
		[(NSObject*)myDelegate performSelector:@selector(messageReceived:onConnection:) 
					    withObject:message 
					    withObject:self];
	    
	    if (message.type == kConnectionAllowed)
	    {	
		myIsAuthenticated = YES;
		[self performSelectorOnMainThread:@selector(_notifyConnect) 
				       withObject:nil 
				    waitUntilDone:YES];
		
		if (message.payloadData)
		{
		    // Decrypt the payload with our private key
		    NSData * private_key = [[BriefcaseConnection briefcaseKeyPair] privateKey];
		    [message decryptWithPrivateKey:private_key];
		    
		    // Get the symmetric session key from the payload
		    self.sessionKey = message.payloadData;
		    
//		    NSLog(@"Symmetric key - client %@", self.sessionKey);
		}
	    }
	    else if (message.channelID > 0)
	    {
		// Try to find the channel
		BriefcaseChannel * channel;
		channel = [myChannelsByID objectForKey:[NSNumber numberWithDouble:message.channelID]];
		
		if (channel)
		    [channel processMessage:message];
	    }
	    
	    @synchronized(myMessagesByTag)
	    {
		[myMessagesByTag removeObjectForKey:[NSNumber numberWithLong:tag]];
	    }
	}
    }    
}

@end

#pragma mark Private Methods

@implementation BriefcaseConnection (Private)

- (void)_connect
{
    NSError * error = nil;
    if (![mySocket connectToHost:myHostName onPort:myPort error:&error])    
    {
	NSLog(@"Connection failed: %@",error);
	[self performSelectorOnMainThread:@selector(_notifyFailure) withObject:nil waitUntilDone:NO];
    }
}

- (void)_sendMessage:(BriefcaseMessage*)message
{
    message.transmitState = kDefault;
    NSNumber * tag_number = [NSNumber numberWithLong:message.tag]; 
    
    @synchronized(myMessagesByTag)
    {
	[myMessagesByTag setObject:message forKey:tag_number];
    }

    // Build the package
    NSData * header_data = message.headerData;
    NSData * payload_data = message.payloadData;
    
    NSUInteger size = [header_data length];
    if (payload_data)
	size += [payload_data length];
    
    NSMutableData * package = [[NSMutableData alloc] initWithCapacity:size];
    [package appendData:header_data];
    if (payload_data)
	[package appendData:payload_data];
    
    [mySocket writeData:package withTimeout:kSocketWriteTimeout tag:message.tag];
    
    [package release];
}

- (void)_readMessageHeader:(BriefcaseMessage*)message
{
    if (myIsAwaitingHeader)
    {
	// We cannot read another header until we have queued the read for
	// the payload of the header we are expecting
	[myQueuedHeaderReads addObject:message];
    }
    else
    {
	[mySocket readDataToLength:kHeaderDataSize withTimeout:kSocketReadTimeout tag:message.tag];
	myIsAwaitingHeader = YES;
    }
}

- (void)_notifyDisconnect
{
    if (myDelegate)
	[myDelegate connectionTerminated:self];
    
    NSNotificationCenter * notification_center = [NSNotificationCenter defaultCenter];
    [notification_center postNotificationName:kConnectionTerminated object:self];
}

- (void)_notifyConnect
{
    if (myDelegate)
	[myDelegate connectionEstablished:self];
    
    NSNotificationCenter * notification_center = [NSNotificationCenter defaultCenter];
    [notification_center postNotificationName:kConnectionEstablished object:self];
}

@end
