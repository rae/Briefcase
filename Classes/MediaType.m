//
//  MediaType.m
//  Briefcase
//
//  Created by Michael Taylor on 03/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "MediaType.h"
#import "BriefcaseAppDelegate.h"
#import "MediaViewerController.h"
#import "FileAction.h"
#import "File.h"

@implementation MediaType

- (BOOL)isViewable
{
    return YES;
}

- (UIViewController*)viewControllerForFile:(File*)file
{	    
    MediaViewerController * controller;
    controller = [[MediaViewerController alloc] initWithPath:file.path];
    return [controller autorelease];
}

- (NSArray*)getFileSpecificActions
{
    FileAction * open_action, * itunes_action;
    
    open_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Play File on Mac", @"Label for file action that plays a media file on a connected Macintosh computer")
					   target:self 
					 selector:@selector(viewFileOnMac:connection:) 
				      requiresMac:YES];
    
    itunes_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Add File to iTunes Library", @"Label for file action that adds a media file to the iTunes library of the connected Mac")
					   target:self 
					 selector:@selector(addFileToiTunes:connection:) 
				      requiresMac:YES];
    
    return [NSArray arrayWithObjects:open_action, itunes_action, nil];
}

- (NSArray*)addFileToiTunes:(File*)file connection:(BCConnection*)connection
{
    return [FileAction operationsForUploadOfFile:file withRemoteShellCommand:@"osascript -e 'tell application \"iTunes\"' -e 'add (POSIX file \"%@\") to playlist \"Library\" of source \"Library\"' -e 'end tell'"];
}

- (NSArray*)viewFileOnMac:(File*)file connection:(BCConnection*)connection
{
    return [FileAction operationsForUploadOfFile:file withRemoteShellCommand:@"/usr/bin/open \"%@\""];
}

@end
