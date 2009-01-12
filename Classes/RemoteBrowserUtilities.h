//
//  RemoteBrowserUtilities.h
//  Briefcase
//
//  Created by Michael Taylor on 21/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SFTPSession;

@interface RemoteBrowserUtilities : NSObject {

}

+ (NSArray*)filterFileList:(NSArray*)file_attribute_list 
		remotePath:(NSString*)remote_path
		showHidden:(BOOL)show_hidden 
		 showFiles:(BOOL)show_files;

+ (NSArray*)readRemoteDirectory:(NSString*)remote_path 
		     showHidden:(BOOL)show_hidden 
		      showFiles:(BOOL)show_files
		    sftpSession:(SFTPSession*)session;
@end
