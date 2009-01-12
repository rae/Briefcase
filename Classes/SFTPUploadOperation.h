//
//  UploadOperation.h
//  Briefcase
//
//  Created by Michael Taylor on 28/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSHOperation.h"

@class Connection;

@interface SFTPUploadOperation : SSHOperation 
{
    NSString *	    myLocalPath;
    NSString *	    myRemotePath;
    BOOL	    myForceOverwrite;
}

@property (nonatomic,assign) BOOL forceOverwrite;

- (id)initWithLocalPath:(NSString*)path 
	     remotePath:(NSString*)remotePath
	     connection:(Connection*)connection;

- (id)initWithLocalPath:(NSString*)path 
	     remotePath:(NSString*)remotePath 
		 onHost:(NSString*)host
	       username:(NSString*)username
		   port:(NSInteger)port;

- (void)main;

@end
