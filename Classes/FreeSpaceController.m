//
//  FreeSpaceController.m
//  Briefcase
//
//  Created by Michael Taylor on 09/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "FreeSpaceController.h"
#import "DownloadProgress.h"

#import "NetworkOperation.h"
#import "File.h"

FreeSpaceController * theFreeSpaceController = nil;
NSString * kFreeSpaceChanged = @"Free Space Changed";
static int kInvalidSpace = -1;

@interface FreeSpaceController (Private)

- (long long)_freeSpaceOnDevice;
- (void)_initializeBaseUsedSpace;
- (void)_recalculateFreeSpace;

@end

@implementation FreeSpaceController

+ (FreeSpaceController*)sharedController
{
    if (!theFreeSpaceController)
	theFreeSpaceController = [[FreeSpaceController alloc] init];
    return theFreeSpaceController;
}

- (id) init
{
    self = [super init];
    if (self != nil) 
    {
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	
	[center addObserver:self 
		   selector:@selector(_networkOperationBegan:) 
		       name:kNetworkOperationBegan
		     object:nil];
	
	[center addObserver:self 
		   selector:@selector(_networkOperationEnded:) 
		       name:kNetworkOperationEnd 
		     object:nil];
	
	[center addObserver:self 
		   selector:@selector(_networkOperationProgress:) 
		       name:kNetworkOperationProgress 
		     object:nil];
	
	[center addObserver:self 
		   selector:@selector(_fileDeleted:) 
		       name:kFileDeleted 
		     object:nil];
	[center addObserver:self 
		   selector:@selector(_directoryDeleted:) 
		       name:kDirectoryDeleted 
		     object:nil];
	
	myBaseFreeSpace = kInvalidSpace;
	myBaseUsedSpace = kInvalidSpace;
	
	[self performSelectorInBackground:@selector(_initializeBaseUsedSpace) 
			       withObject:nil];
	
	myDownloads = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark Properties

- (long long)freeSpace
{
    if ([myDownloads count] > 0)
    {
	if (myCalculatedFreeSpace == kInvalidSpace)
	    [self _recalculateFreeSpace];
	return myCalculatedFreeSpace;
    }
    else
    {
	long long free_space = [self _freeSpaceOnDevice];
	return free_space;
    }
}

- (long long)unreservedSpace
{
    if ([myDownloads count] > 0)
    {
	if (myCalculatedUnreservedSpace == kInvalidSpace)
	    [self _recalculateFreeSpace];
	return myCalculatedUnreservedSpace;
    }
    else
    {
	long long free_space = [self _freeSpaceOnDevice];
	return free_space;
    }
}

- (long long)usedSpace
{
    if ([myDownloads count] > 0)
    {
	if (myCalculatedUsedSpace == kInvalidSpace)
	    [self _recalculateFreeSpace];
	return myCalculatedUsedSpace;
    }
    else
	return (myBaseUsedSpace == kInvalidSpace) ? 0 : myBaseUsedSpace;
}

@end

@implementation FreeSpaceController (Private)

- (long long)_freeSpaceOnDevice
{ 
    NSArray *  paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documents_directory = [paths objectAtIndex:0];
    
    NSFileManager * manager = [NSFileManager defaultManager];
    NSError * error;
    NSDictionary * attributes = [manager attributesOfFileSystemForPath:documents_directory 
								 error:&error];
    NSNumber * free_space = [attributes objectForKey:NSFileSystemFreeSize];
    return [free_space longLongValue];
}

- (void)_recalculateFreeSpace
{
    @synchronized (self)
    {
	myCalculatedFreeSpace = myBaseFreeSpace;
	myCalculatedUnreservedSpace = myBaseFreeSpace;
	myCalculatedUsedSpace = myBaseUsedSpace;	
    }
    
    for (id <DownloadProgress> op in myDownloads)
    {
	myCalculatedFreeSpace -= op.downloadedBytes;
	myCalculatedUnreservedSpace -= op.downloadedBytes + op.remainingBytes;
	myCalculatedUsedSpace += op.downloadedBytes;
    }
}

- (void)_setNeedsRecalculation
{
    myCalculatedFreeSpace = kInvalidSpace;
    myCalculatedUnreservedSpace = kInvalidSpace;
    myCalculatedUsedSpace = kInvalidSpace;
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kFreeSpaceChanged object:self];
}

- (void)_networkOperationBegan:(NSNotification*)center
{
    if ([[center object] conformsToProtocol:@protocol(DownloadProgress)])
    {
	if ([myDownloads count] == 0)
	{
	    // Take a snapshop of the free space on the device   
	    myBaseFreeSpace = [self _freeSpaceOnDevice];
	    myCalculatedFreeSpace = myBaseFreeSpace;
	    myCalculatedUnreservedSpace = myBaseFreeSpace;
	    
	    @synchronized (self)
	    {
		myCalculatedUsedSpace = myBaseUsedSpace;
	    }
	}
	[myDownloads addObject:[center object]];
    }
    
    // We need to recalculate
    [self _setNeedsRecalculation];
}

- (void)_networkOperationEnded:(NSNotification*)center
{
    if ([[center object] conformsToProtocol:@protocol(DownloadProgress)])
    {
	id <DownloadProgress> op = [center object];
	
	[myDownloads removeObject:[center object]];
	
	@synchronized (self)
	{
	    myBaseUsedSpace += op.downloadedBytes;
	}
	
	// We need to recalculate
	[self _setNeedsRecalculation];
    }
}

- (void)_networkOperationProgress:(NSNotification*)notification
{
    // We need to recalculate
    [self _setNeedsRecalculation];
}

- (void)_fileDeleted:(NSNotification*)notification
{
    // Account for the file deletion
    File * file = [notification object];
    if (file && file.downloadComplete)
    {
	myBaseUsedSpace -= [file.size floatValue];
	[self _setNeedsRecalculation];
    }
}

- (void)_directoryDeleted:(NSNotification*)notification
{
    myBaseUsedSpace = [File totalSizeOfAllFiles];
    [self _setNeedsRecalculation];
}

- (void)_initializeBaseUsedSpace
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    long long space_used = [File totalSizeOfAllFiles];
    
    @synchronized(self)
    {
	myBaseUsedSpace = space_used;
    }
    [self performSelectorOnMainThread:@selector(_setNeedsRecalculation) 
			   withObject:nil 
			waitUntilDone:NO];
    
    [pool release];
}

@end

