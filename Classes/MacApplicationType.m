//
//  ApplicationType.m
//  Briefcase
//
//  Created by Michael Taylor on 24/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "MacApplicationType.h"
#import "FileAction.h"
#import "file.h"
#import "SSHCommandOperation.h"

@implementation MacApplicationType

- (id) init
{
    self = [super initWithWeight:10];
    if (self != nil) {
	myExtentions = [NSSet setWithObjects:
			@"app",
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
    FileAction * install_action;
    
    NSMutableArray * actions = [NSMutableArray arrayWithArray:[super getFileSpecificActions]];
    
    install_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Install on Mac", @"Label for file action that installs the given package on the remote Mac")
					   target:self 
					 selector:@selector(installApp:connection:) 
				      requiresMac:YES];
    
    [actions addObject:install_action];
    
    return actions;
}

- (NSArray*)installApp:(File*)file connection:(Connection*)connection
{
    NSArray * ops = [FileAction operationsForUploadOfFile:file toPath:@"/Applications"];
    
    // Add a command operation to show the installed application on the remote Mac
    NSString * remote_path = [@"/Applications" stringByAppendingPathComponent:file.fileName];
    NSString * format = @"osascript -e 'tell application \"Finder\"' -e 'reveal (POSIX file \"%@\")' -e 'end tell'";
    NSString * command = [NSString stringWithFormat:format, remote_path];
    SSHCommandOperation * command_op;
    command_op = [[SSHCommandOperation alloc] initWithCommand:command connection:connection];
    [command_op addDependency:[ops objectAtIndex:0]];
     
    return [ops arrayByAddingObject:command_op];
}


@end
