//
//  FileAction.m
//  Briefcase
//
//  Created by Michael Taylor on 03/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "FileAction.h"
#import "File.h"
#import "BCConnection.h"
#import "NetworkOperationQueue.h"
#import "ConnectionController.h"
#import "SFTPUploadOperation.h"
#import "SSHUploadAndUnzipOperation.h"
#import "SSHCommandOperation.h"
#import "SystemInformation.h"

@implementation FileAction

@synthesize title =		myTitle;
@synthesize operationAction =	myOperationAction;
@synthesize target =		myTarget;
@synthesize requiresMac =	myRequiresMac;

+(FileAction*)fileActionWithTitle:(NSString*)title 
			   target:(id)target
			 selector:(SEL)operationAction 
		      requiresMac:(BOOL)mac
{
    FileAction * file_action = [[FileAction alloc] init];
    
    file_action.title = title;
    file_action.operationAction = operationAction;
    file_action.target = target;
    file_action.requiresMac = mac;
    
    return [file_action autorelease];
}

- (NSString*)identifierForFile:(File*)file
{
    return [NSString stringWithFormat:@"%@: %@", myTitle, file.path];
}

- (NSArray*)queueOperationsForFile:(File*)file connection:(BCConnection*)connection
{
    NSArray * operations = nil;
    
    @try 
    {
	// Gather the operations for this action
	operations = [myTarget performSelector:myOperationAction 
				    withObject:file 
				    withObject:connection];
	
	for (NSOperation * stalled in [[NetworkOperationQueue sharedQueue] operations])
	{
	    NSLog(@"Ready %d  Finished %d",(int)[stalled isReady], (int)[stalled isFinished]);
	}
	
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

- (UITableViewCellAccessoryType)accessoryType
{
    return UITableViewCellAccessoryNone;
}

#pragma mark Action Helpers

+ (NSArray*)operationsForUploadOfFile:(File*)file toPath:(NSString*)remote_path 
{
    NSArray * result = nil;
    
    NSString * file_name = file.fileName;
    remote_path = [remote_path stringByAppendingPathComponent:file_name];
    
    @try 
    {
	ConnectionController * controller = [ConnectionController sharedController];
	
	if (file.isZipped)
	{
	    SSHUploadAndUnzipOperation * op;
	    op = [SSHUploadAndUnzipOperation alloc];
	    [op initWithLocalPath:file.path remotePath:remote_path connection:controller.currentConnection];
	    result = [NSArray arrayWithObject:op];
	    [op release];
	}
	else
	{
	    SFTPUploadOperation * op;
	    op = [SFTPUploadOperation alloc];
	    [op initWithLocalPath:file.path remotePath:remote_path connection:controller.currentConnection];
	    result = [NSArray arrayWithObject:op];
	    [op release];
	}
    }
    @catch (NSException * e) {
	UIAlertView *alert = 
	alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Operation Error", @"Title for dialogs that show error messages about failed network operations") 
					   message:[e reason]
					  delegate:nil 
				 cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
				 otherButtonTitles:nil];
	[alert show];	
	[alert release];
    }
    
    return result;
}

+ (NSArray*)operationsForUploadOfFile:(File*)file withRemoteShellCommand:(NSString*)command
{
    NSArray * result = nil;
    
    ConnectionController * controller = [ConnectionController sharedController];
    SystemInformation * sys_info = controller.currentSystemInformation;
    
    NSString * temp_dir;
    
    if (sys_info)
	temp_dir = sys_info.tempDir;
    else
	temp_dir = @"/tmp";
    
    NSString * remote_path = [temp_dir stringByAppendingPathComponent:[file.fileName lastPathComponent]];
    
    SFTPUploadOperation * upload_op;
    SSHCommandOperation * command_op;
    @try 
    {
	ConnectionController * controller = [ConnectionController sharedController];
	if (file.isZipped)
	{
	    upload_op = [SSHUploadAndUnzipOperation alloc];
	    [upload_op initWithLocalPath:file.path remotePath:remote_path connection:controller.currentConnection];
	}
	else
	{
	    upload_op = [SFTPUploadOperation alloc];
	    [upload_op initWithLocalPath:file.path remotePath:remote_path connection:controller.currentConnection];
	}
	
	// We are writing to the temp dir.  Overwrite temp files
	// without mercy
	upload_op.forceOverwrite = YES;
	
	NSString * formatted_command = [NSString stringWithFormat:command, remote_path];
	command_op = [SSHCommandOperation alloc];
	[command_op initWithCommand:formatted_command connection:controller.currentConnection];
	
	[command_op addDependency:upload_op];
	
	result = [NSArray arrayWithObjects:upload_op, command_op, nil];
	[upload_op release];
	[command_op release];
    }
    @catch (NSException * e) {
	UIAlertView *alert = 
	alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Operation Error", @"Title for dialogs that show error messages about failed network operations") 
					   message:[e reason]
					  delegate:nil 
				 cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
				 otherButtonTitles:nil];
	[alert show];	
	[alert release];
    }
    
    return result;
}


@end
