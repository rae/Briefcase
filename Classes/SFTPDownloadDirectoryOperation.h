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
#import "DownloadProgress.h"

@interface SFTPDownloadDirectoryOperation : SSHOperation <SFTPFileDownloaderDelegate, DownloadProgress>
{
    NSString *	    myRemotePath;
    NSInteger	    myDownloadCount;
    NSInteger	    myDownloadComplete;
    
    NSUInteger	    myDownloadedBytes;
    NSUInteger	    myTotalBytes;
    NSUInteger	    myCurrentFileBytes;
    
    NSDictionary *  myJobAttributes;
}

@property (nonatomic,readonly)	NSUInteger  downloadedBytes;

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
