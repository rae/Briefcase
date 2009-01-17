//
//  BriefcaseUploadOperation.m
//  Briefcase
//
//  Created by Michael Taylor on 13/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BriefcaseUploadOperation.h"
#import "ConnectionController.h"
#import "BriefcaseConnection.h"
#import "File.h"
#import "Utilities.h"

#define kBlockSize (1024*256)

enum BriefcaseUploadState 
{
    kStarting,
    kWaitingForFreeSpace,
    kWaitingForHeaderResponse,
    kWaitingForDataResponse,
    kUploadFinished,
    kUploadCancelled,
    kUploadCancelledResponse,
    kWaitingForFinishedResponse
};

#pragma mark Private Method Declarations

@interface BriefcaseUploadOperation (Private)

- (void)_sendFileHeader:(File*)file;
- (void)_sendSomeData;
- (void)_sendCancelled;

@end

#pragma mark BriefcaseUploadOperation Implementation

@implementation BriefcaseUploadOperation

- (id)initWithConnection:(BriefcaseConnection*)connection file:(File*)file
{
    self = [super init];
    if (self != nil) 
    {
	myBriefcaseConnection = [connection retain];
	myFile = [file retain];
	myState = kStarting;
	myDoneCondition = [[NSCondition alloc] init];
	mySentCancel = NO;
	myIsFinished = NO;
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(connectionTerminated:)
		       name:kConnectionTerminated 
		     object:connection];
    }
    return self;
}

- (void) dealloc
{
    [myBriefcaseConnection release];
    [myFile release];
    [myChannel release];
    [myDoneCondition release];
    [myFileHandle release];
    [super dealloc];
}

-(void)main
{
    [self beginTask:NSLocalizedString(@"Running remote command", @"Log message when an upload begins")];
    
    // Open a channel
    myChannel = [myBriefcaseConnection openChannelWithDelegate:self];
    
    // Reques the free space on the other device
    myState = kWaitingForFreeSpace;
    BriefcaseMessage * message = [BriefcaseMessage messageWithType:kFreeSpaceRequest];
    [myChannel sendMessage:message];
    
    // Wait for the final completion of this operation
    [myDoneCondition lock];
    
    while (myState != kUploadFinished && myState != kUploadCancelled) 
    {
	[myDoneCondition wait];
    }
    
    [myDoneCondition unlock];
    
    if (myState == kUploadFinished)
	[self endTask];
    else
	[self endTaskWithError:@"Upload of file failed"];
}
    
- (void)channelResponseRecieved:(BriefcaseMessage*)message
{
    BOOL ok = FALSE;
    
    switch (myState)
    {
	case kWaitingForFreeSpace:
	{
	    if (message.type == kFreeSpaceResponse)
	    {
		NSNumber * free_space_number = message.payloadNumber;
		long long free_space = [free_space_number longLongValue];
		long long file_size = [myFile.size longLongValue];
		if (file_size > free_space)
		{
		    UIAlertView * alert;
		    NSString * format = NSLocalizedString(@"There is not enough space on the remote device to upload \"%@\".  You would require %@ more space.", @"Message displayed when the user tries to download a file to big to fit on this device");
		    NSString * error = [NSString stringWithFormat:format, myFile.fileName, [Utilities humanReadibleMemoryDescription:(file_size - free_space)]];
		    alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"File Too Large", @"Title for message telling the user a file is too large for this device") 
						       message:error
						      delegate:nil 
					     cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
					     otherButtonTitles:nil];
		    [alert show];	
		    [alert release];
		    
		    [self cancel];
		    myState = kUploadCancelled;
		    [myDoneCondition lock];
		    [myDoneCondition signal];
		    [myDoneCondition unlock];
		    break;
		}
		
		// We're ok for space, send the file header
		[self _sendFileHeader:myFile];
		myState = kWaitingForHeaderResponse;
		
		ok = TRUE;
	    }
	    break;
	}
	case kWaitingForHeaderResponse:
	{
	    if (message.type == kFileHeaderResponse)
	    {
		if (self.isCancelled)
		    break;
		
		// Open up the local file for reading
		myFileHandle = [NSFileHandle fileHandleForReadingAtPath:myFile.path];
		if (myFileHandle)
		{
		    [myFileHandle retain];
		    [self _sendSomeData];
		    myState = kWaitingForDataResponse;
		    ok = TRUE;
		}
	    }
	    else if (message.type == kFileCancelled)
	    {
		// The other end cancelled the transfer
		[self cancel];
		// We don't need to send the cancel message
		mySentCancel = YES;
	    }
	    break;
	}
	case kWaitingForDataResponse:
	{
	    if (message.type == kFileDataResponse && !self.isCancelled)
	    {
		if (myIsFinished)
		{
		    // Send a final message saying we're done
		    message = [BriefcaseMessage messageWithType:kFileDone];
		    [myChannel sendMessage:message];
		    myState = kWaitingForFinishedResponse;
		}
		else
		{
		    [self _sendSomeData];
		}
		ok = TRUE;
	    }
	    else if (message.type == kFileCancelled)
	    {
		// The other end cancelled the transfer
		[self cancel];
		// We don't need to send the cancel message
		mySentCancel = YES;
	    }
	    break;
	}
	case kWaitingForFinishedResponse:
	{
	    if (message.type == kFileDoneResponse)
	    {
		[myFileHandle closeFile];
		[myFileHandle release];
		myFileHandle = nil;
		[myDoneCondition lock];
		[myDoneCondition signal];
		[myDoneCondition unlock];
		myState = kUploadFinished;
		ok = TRUE;
	    }
	    break;
	}
    }
    
    if (!ok || self.isCancelled)
    {
	[self _sendCancelled];
	myState = kUploadCancelled;
	[myDoneCondition lock];
	[myDoneCondition signal];
	[myDoneCondition unlock];
    }
}

- (void)connectionTerminated:(NSNotification*)notification
{
    [self cancel];
    myState = kUploadCancelled;
    [myDoneCondition lock];
    [myDoneCondition signal];
    [myDoneCondition unlock];
}

- (NSString*)title
{
    return NSLocalizedString(@"Uploading", @"Label shown in activity view describing the upload operation");
}

- (NSString*)description
{
    return myFile.fileName;
}

- (NSString*)identifier
{
    return nil;
}

@end

#pragma mark Private Methods

@implementation BriefcaseUploadOperation (Private)

- (void)_sendSomeData
{
    NSData * data = [myFileHandle readDataOfLength:kBlockSize];
    
    if (!data)
    {
	myState = kUploadCancelled;
	[myDoneCondition lock];
	[myDoneCondition signal];
	[myDoneCondition unlock];
    } 
    
    myBytesRead += [data length];

    BriefcaseMessage * message = [BriefcaseMessage messageWithType:kFileData];
    message.payloadData = data;
    [myChannel sendMessage:message];
    
    if ([data length] < kBlockSize || myBytesRead == [myFile.size longLongValue])
    {
	// We're at the end
	myIsFinished = YES;
    }
    
    self.progress = (float)myBytesRead / [myFile.size floatValue];
}

- (void)_sendFileHeader:(File*)file
{
    NSDictionary * header_dictionary;
    header_dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			 [myFile.path lastPathComponent], @"filename",
			 myFile.size, @"size",
			 myFile.iconData, @"icon",
			 myFile.previewData, @"preview",
			 myFile.webArchiveData, @"webarchive",
			 [NSNumber numberWithBool:myFile.isZipped], @"zipped",
			 nil
			 ];
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:header_dictionary];
    
    BriefcaseMessage * message = [BriefcaseMessage messageWithType:kFileHeader];
    message.payloadData = data;
    [myChannel sendMessage:message];
}

- (void)_sendCancelled
{
    if (!mySentCancel)
    {
	BriefcaseMessage * message = [BriefcaseMessage messageWithType:kFileCancelled];
	[myChannel sendMessage:message];
	mySentCancel = YES;
    }
}

@end
