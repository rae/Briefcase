//
//  DirectoryReadOperation.m
//  Briefcase
//
//  Created by Michael Taylor on 14/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "DirectoryReadOperation.h"
#import "RemoteFileBrowserController.h"
#import "SFTPSession.h"
#import "BlockingAlert.h"

@implementation DirectoryReadOperation


- (id)initWithPath:(NSString*)path
{
    if (self = [super init])
    {
	myPath = [path retain];
    }
    return self;
}

- (void)main
{
    RemoteFileBrowserController * controller = [RemoteFileBrowserController sharedController];
    SFTPSession * session = controller.sftpSession;
    if (session && myPath)
    {
	NSArray * directory_items = nil;
	
	@try 
	{
	    directory_items = [session readDirectory:myPath];
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
	if (directory_items)
	    [controller addDirectoryToCache:myPath withItems:directory_items];
	else
	    // Could not read directory
	    [controller performSelectorOnMainThread:@selector(directoryUpdateFailedForPath:) 
					 withObject:myPath 
				      waitUntilDone:NO];
    }
}

- (void) dealloc
{
    if (myPath)
	[myPath release];
    
    [super dealloc];
}


@end
