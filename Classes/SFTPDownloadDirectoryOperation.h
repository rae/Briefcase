//
//  SFTPDownloadDirectory.h
//  Briefcase
//
//  Created by Michael Taylor on 18/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SSHOperation.h"
#import "SFTPFileDownloader.h"

@interface SFTPDownloadDirectoryOperation : SSHOperation <SFTPFileDownloaderDelegate>
{
    NSString *	    myRemotePath;
    NSInteger	    myDownloadCount;
    NSInteger	    myDownloadComplete;
    
    NSDictionary *  myJobAttributes;
}

+ (NSArray*)operationsForUnfinishedJobs;

- (id)initWithPath:(NSString*)path connection:(SSHConnection*)connection;

- (id)initWithPath:(NSString*)path 
	      host:(NSString*)host 
	  username:(NSString*)username 
	      port:(NSInteger)port;

- (void)_registerJob:(NSString*)path 
		host:(NSString*)host 
	    username:(NSString*)username 
		port:(NSInteger)port;
- (void)_deregisterJob;

@end
