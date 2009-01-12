//
//  SFTPFileDownloader.h
//  Briefcase
//
//  Created by Michael Taylor on 19/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SFTPSession;
@class SFTPFileAttributes;

@protocol SFTPFileDownloaderDelegate

- (void)sftpFileDownloadProgress:(float)progress;
- (BOOL)sftpFileDownloadCancelled;

@end


@interface SFTPFileDownloader : NSObject 
{
    id <SFTPFileDownloaderDelegate> myDelegate;
    SFTPSession *		    mySFTPSession;
}

@property (nonatomic,retain) id <SFTPFileDownloaderDelegate> delegate;

- (id)initWithSFTPSession:(SFTPSession*)session;

- (void)downloadRemoteFile:(NSString*)remote_path 
		    toLocalRelativePath:(NSString*)local_path;

- (void)downloadRemoteFile:(NSString*)remote_path 
      remoteFileAttributes:(SFTPFileAttributes*)attributes
       toLocalRelativePath:(NSString*)local_path;

-(void)_raiseException:(NSString*)description;

@end
