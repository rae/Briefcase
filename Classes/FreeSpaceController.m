//
//  FreeSpaceController.m
//  Briefcase
//
//  Created by Michael Taylor on 09/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "FreeSpaceController.h"
#import "SFTPDownloadOperation.h"

#import "NetworkOperation.h"

FreeSpaceController * theFreeSpaceController = nil;
NSString * kFreeSpaceChanged = @"Free Space Changed";
static int kInvalidSpace = -1;

@interface FreeSpaceController (Private)

- (long long)_freeSpaceOnDevice;
- (long long)_spaceUsedByBriefcaseFiles;
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
	
	myBaseFreeSpace = kInvalidSpace;
	myBaseUsedSpace = kInvalidSpace;
	
	[self performSelectorInBackground:@selector(_initializeBaseUsedSpace) 
			       withObject:nil];
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

- (long long)_spaceUsedByBriefcaseFiles
{
    long long result = 0;
    
    NSDictionary * attributes;
    NSError  * error = nil;
    NSString * file, * full_path;
    NSArray  * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documents_directory = [paths objectAtIndex:0];
    
    NSFileManager * manager = [NSFileManager defaultManager];
    NSDirectoryEnumerator * directory_enumerator;
    directory_enumerator = [manager enumeratorAtPath:documents_directory];
    
    while (file = [directory_enumerator nextObject]) 
    {
	full_path = [documents_directory stringByAppendingPathComponent:file];
	attributes = [manager attributesOfItemAtPath:full_path error:&error];
	
	if (!error)
	{
	    NSNumber * size = [attributes objectForKey:NSFileSize];
	    if (size)
		result += [size longLongValue];
	}
    }
    
    return result;
}

- (void)_recalculateFreeSpace
{
    @synchronized (self)
    {
	myCalculatedFreeSpace = myBaseFreeSpace;
	myCalculatedUnreservedSpace = myBaseFreeSpace;
	myCalculatedUsedSpace = myBaseUsedSpace;	
    }
    
    for (SFTPDownloadOperation * op in myDownloads)
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
    if ([[center object] isKindOfClass:[SFTPDownloadOperation class]])
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
    if ([[center object] isKindOfClass:[SFTPDownloadOperation class]])
    {
	SFTPDownloadOperation * op = [center object];
	
	[myDownloads removeObject:[center object]];
	
	@synchronized (self)
	{
	    myBaseFreeSpace += op.downloadedBytes;
	}
    }
}

- (void)_networkOperationProgress:(NSNotification*)center
{
    // We need to recalculate
    [self _setNeedsRecalculation];
}

- (void)_initializeBaseUsedSpace
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    long long space_used = [self _spaceUsedByBriefcaseFiles];
    
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

