//
//  DocumentType.m
//  Briefcase
//
//  Created by Michael Taylor on 03/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "DocumentType.h"
#import "File.h"
#import "BriefcaseAppDelegate.h"
#import "DocumentViewController.h"
#import "FileAction.h"

@implementation DocumentType

#if BRIEFCASE_LITE

- (id) init
{
    self = [super initWithWeight:10];
    if (self != nil) {
	myExtentions = [NSSet setWithObjects:
			@"pdf",
			@"pages", 
			@"numbers", 
			@"key", 
			@"doc", 
			@"docx", 
			@"xls", 
			@"xlsx",  
			@"ppt", 
			@"pps", 
			@"cwk", 
			@"pptx", 
			@"xml",
			@"txt",
			@"html",
			@"webarchive",
			@"log",
			nil];
	[myExtentions retain];
    }
    return self;
}

#else

- (id) init
{
    self = [super initWithWeight:10];
    if (self != nil) {
	myExtentions = [NSSet setWithObjects:
			@"pdf",
			@"pages", 
			@"numbers", 
			@"key", 
			@"doc", 
			@"docx", 
			@"xls", 
			@"xlsx",  
			@"ppt", 
			@"pps", 
			@"cwk", 
			@"pptx", 
			@"xml",
			@"txt",
			@"rtf",
			@"rtfd",
			@"html",
			@"webarchive",
			@"log",
			nil];
	[myExtentions retain];
	//TODO: There's probably more!!
    }
    return self;
}

#endif

- (UIViewController*)viewControllerForFile:(File*)file
{	 
    return [DocumentViewController documentViewControllerForFile:file];
}


- (BOOL)isViewable
{
    return YES;
}

- (NSArray*)getUploadActionsForType
{
    FileAction * documents_action;
    documents_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Documents", @"Documents folder in the user's directory")
						target:self 
					      selector:@selector(uploadToDocumentsWithFile:connection:) 
					   requiresMac:NO];
    
    return [NSArray arrayWithObject:documents_action];
}

- (NSArray*)getFileSpecificActions
{
    FileAction * open_action;
    
    open_action = [FileAction fileActionWithTitle:NSLocalizedString(@"View Document on Mac", @"Label for file action that views a document on a connected Macintosh computer")
					   target:self 
					 selector:@selector(viewFileOnMac:connection:) 
				      requiresMac:YES];
    
    return [NSArray arrayWithObjects:open_action, nil];
}

- (NSArray*)viewFileOnMac:(File*)file connection:(BCConnection*)connection
{
    return [FileAction operationsForUploadOfFile:file withRemoteShellCommand:@"/usr/bin/open \"%@\""];
}

- (NSArray*)uploadToDocumentsWithFile:(File*)file connection:(BCConnection*)connection
{
    NSString * remote_path = @"Documents";
    return [FileAction operationsForUploadOfFile:file toPath:remote_path];
}

@end
