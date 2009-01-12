//
//  CustomLocationAction.m
//  Briefcase
//
//  Created by Michael Taylor on 20/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "CustomLocationAction.h"
#import "NetworkOperationQueue.h"

@implementation CustomLocationAction

@synthesize location = myCustomLocation;

- (id)initWithCustomLocation:(NSString*)location
{
    self = [super init];
    if (self != nil) {
	myCustomLocation = [location retain];
	myRequiresMac = NO;
	self.title = [location lastPathComponent];
    }
    return self;
}

- (NSArray*)queueOperationsForFile:(File*)file connection:(Connection*)connection
{
    NSArray * operations = nil;
    
    @try 
    {
	// Gather the operations for this action
	operations = [FileAction operationsForUploadOfFile:file toPath:myCustomLocation];
		
	for (NSOperation * op in operations)
	    [[NetworkOperationQueue sharedQueue] addOperation:op];
    }
    @catch (NSException * e) 
    {
	UIAlertView *alert = 
	alert = [[UIAlertView alloc] initWithTitle:[e name] 
					   message:[e reason]
					  delegate:nil 
				 cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
				 otherButtonTitles:nil];
	[alert show];	
	[alert release];
	
	operations = nil;
    }
    
    return operations;
}

- (void)setLocation:(NSString*)location
{
    [myCustomLocation release];
    myCustomLocation = [location retain];
    self.title = [location lastPathComponent];
}

@end
