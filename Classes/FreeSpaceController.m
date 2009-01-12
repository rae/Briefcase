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
    }
    return self;
}

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
    myCalculatedFreeSpace = myBaseFreeSpace;
    myCalculatedUnreservedSpace = myBaseFreeSpace;
    myCalculatedUsedSpace = myBaseUsedSpace;
    
    for (SFTPDownloadOperation * op in myDownloads)
    {
	myCalculatedFreeSpace -= op.downloadedBytes;
	myCalculatedUnreservedSpace -= op.downloadedBytes + op.remainingBytes;
	myBaseUsedSpace += op.downloadedBytes;
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
	    
	    myBaseUsedSpace = [self _spaceUsedByBriefcaseFiles];
	    myCalculatedUsedSpace = myBaseUsedSpace;
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
	[myDownloads removeObject:[center object]];
	if ([myDownloads count] == 0)
	    // We'll re-read the file system the next time we're asked
	    myBaseFreeSpace == kInvalidSpace;
    }
}

- (void)_networkOperationProgress:(NSNotification*)center
{
    // We need to recalculate
    [self _setNeedsRecalculation];
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
	return [self _spaceUsedByBriefcaseFiles];
}

@end
