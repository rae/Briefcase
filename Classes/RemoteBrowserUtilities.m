//
//  RemoteBrowserUtilities.m
//  Briefcase
//
//  Created by Michael Taylor on 21/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "RemoteBrowserUtilities.h"
#import "SFTPSession.h"
#import "Utilities.h"

static NSSet * theSystemFiles = nil;

@implementation RemoteBrowserUtilities

NSComparisonResult compareFileAttributes(SFTPFileAttributes * item1, 
					 SFTPFileAttributes * item2, 
					 void * context)
{ return [item1.name caseInsensitiveCompare:item2.name]; }


+ (NSArray*)filterFileList:(NSArray*)file_attribute_list
		remotePath:(NSString*)remote_path
		showHidden:(BOOL)show_hidden 
		 showFiles:(BOOL)show_files
{
    if (!theSystemFiles)
	theSystemFiles = [[NSSet alloc] initWithObjects:
			  @"/Desktop DB",
			  @"/Desktop DF",
			  @"/bin",
			  @"/cores",
			  @"/dev",
			  @"/etc",
			  @"/mach_kernel",
			  @"/mach_kernel.ctfsys",
			  @"/net",
			  @"/private",
			  @"/sbin",
			  @"/usr",
			  @"/var",
			  nil];
    
    // Filter
    NSMutableArray * new_array = [[NSMutableArray alloc] initWithCapacity:[file_attribute_list count]];
    NSString * full_path;
    
    for (SFTPFileAttributes * item in file_attribute_list)
    {
	if (!show_hidden)
	{
	    if ([item.name characterAtIndex:0] == '.')
		continue;
	    
	    full_path = [remote_path stringByAppendingPathComponent:item.name];
	    if ([theSystemFiles containsObject:full_path])
		continue;
	}
	
	if (!show_files && (!item.isDir || [Utilities isBundle:item.name]))
	    continue;
	
	[new_array addObject:item];
    }
    
    [new_array sortUsingFunction:compareFileAttributes context:NULL];
    
    return new_array;    
}

+ (NSArray*)readRemoteDirectory:(NSString*)remote_path 
		     showHidden:(BOOL)show_hidden 
		      showFiles:(BOOL)show_files
		    sftpSession:(SFTPSession*)session
{
    // Read remote directory
    NSArray * items = [session readDirectory:remote_path];
    return [RemoteBrowserUtilities filterFileList:items
				       remotePath:remote_path
				       showHidden:show_hidden 
					showFiles:show_files];
}

@end
