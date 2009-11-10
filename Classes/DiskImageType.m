//
//  DiskImageType.m
//  Briefcase
//
//  Created by Michael Taylor on 08/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "DiskImageType.h"

#import "FileAction.h"

@implementation DiskImageType

- (id) init
{
    self = [super initWithWeight:10];
    if (self != nil) {
	myExtentions = [NSSet setWithObjects:
			@"dmg",
			@"iso", 
			@"cdr",
			nil];
	[myExtentions retain];
    }
    return self;
}

- (BOOL)isViewable
{
    return NO;
}

- (NSArray*)getFileSpecificActions
{
    FileAction * open_action;
    
    open_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Mount Disk Image", @"Label for file action that mounts the given disk image on the remote Mac")
					   target:self 
					 selector:@selector(mountImageOnMac:connection:) 
				      requiresMac:YES];
    
    return [NSArray arrayWithObject:open_action];
}

- (NSArray*)mountImageOnMac:(File*)file connection:(BCConnection*)connection
{
    return [FileAction operationsForUploadOfFile:file withRemoteShellCommand:@"/usr/bin/open \"%@\""];
}

@end
