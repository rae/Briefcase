//
//  DownloadOperation.h
//  Briefcase
//
//  Created by Michael Taylor on 17/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSHOperation.h"
#import "SFTPFileDownloader.h"
#import "DownloadProgress.h"

@class SFTPSession;
@class SSHConnection;

@interface SFTPDownloadOperation : SSHOperation <SFTPFileDownloaderDelegate, DownloadProgress>
{
    NSString *	    myRemotePath;
    NSString *	    myRemoteSource;
    BOOL	    myResumeDownload;
    BOOL	    myMarkAsZipped;
    NSUInteger	    myRemainingBytes;
    NSUInteger	    myDownloadedBytes;
}

@property (nonatomic,assign)	BOOL	    resumeDownload;
@property (nonatomic,assign)	BOOL	    markAsZipped;
@property (nonatomic,readonly)	NSUInteger  downloadedBytes;
@property (nonatomic,readonly)	NSUInteger  remainingBytes;

- (id)initWithPath:(NSString*)path connection:(SSHConnection*)connection;

- (id)initWithPath:(NSString*)path 
	      host:(NSString*)host 
	  username:(NSString*)username 
	      port:(NSInteger)port;

- (void)main;

@end
