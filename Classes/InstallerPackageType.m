//
//  InstallerPackage.m
//  Briefcase
//
//  Created by Michael Taylor on 27/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "InstallerPackageType.h"

#import "FileAction.h"
#import "SystemInformation.h"
#import "File.h"
#import "NetworkOperation.h"
#import "SSHUploadAndUnzipOperation.h"
#import "SSHCommandOperation.h"

@implementation InstallerPackageType

- (id) init
{
    self = [super initWithWeight:10];
    if (self != nil) {
	myExtentions = [NSSet setWithObjects:
			@"pkg",
			@"mpkg",
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
    
    NSMutableArray * actions = [NSMutableArray arrayWithArray:[super getFileSpecificActions]];
    
    open_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Install on Mac", @"Label for file action that installs the given package on the remote Mac")
					   target:self 
					 selector:@selector(installPackage:connection:) 
				      requiresMac:YES];
    
    [actions addObject:open_action];
    
    return actions;
}

- (NSArray*)installPackage:(File*)file connection:(BCConnection*)connection
{
    NSArray * result = nil;
    
    SystemInformation * sys_info = (SystemInformation*)connection.userData;
    
    NSString * temp_dir;
    
    if (sys_info)
	temp_dir = sys_info.tempDir;
    else
	temp_dir = @"/tmp";
    
    NSString * remote_path = [temp_dir stringByAppendingPathComponent:[file.fileName lastPathComponent]];
    
    @try 
    {
	SSHUploadAndUnzipOperation * upload_op = nil;
	SSHCommandOperation * install_op = nil;
	
	// Operation for uploading the file
	if (file.isZipped)
	    upload_op = [[SSHUploadAndUnzipOperation alloc] initWithLocalPath:file.path remotePath:remote_path connection:connection];
	else
	    upload_op = [[SFTPUploadOperation alloc] initWithLocalPath:file.path remotePath:remote_path connection:connection];
	
	// Operation for installing
	NSString * format = @"/usr/bin/sudo /usr/bin/nohup /usr/sbin/installer -package \"%@\" -target / > /dev/null";
	NSString * formatted_command = [NSString stringWithFormat:format, remote_path];
	install_op = [[SSHCommandOperation alloc] initWithCommand:formatted_command connection:connection];
	
	if (connection.password)
	{
	    NSData * password_data = [connection.password dataUsingEncoding:NSUTF8StringEncoding];
	    install_op.commandInput = password_data;
	}
	
	[install_op addDependency:upload_op];
	
	result = [NSArray arrayWithObjects:upload_op, install_op, nil];
	[upload_op release];
	[install_op release];
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
