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

typedef enum
{
    kAsk,
    kSkipAllDuplicates,
    kOverwriteAllDuplicates
} DownloaderDuplicateState;

@protocol SFTPFileDownloaderDelegate

- (void)sftpFileDownloadProgress:(float)progress bytes:(NSUInteger)bytes;
- (BOOL)sftpFileDownloadCancelled;

@end

@interface SFTPFileDownloader : NSObject 
{
    id <SFTPFileDownloaderDelegate> myDelegate;
    SFTPSession *		    mySFTPSession;
    DownloaderDuplicateState	    myDuplicateState;
}

@property (nonatomic,retain) id <SFTPFileDownloaderDelegate> delegate;
@property (nonatomic,assign) DownloaderDuplicateState duplicateState;

- (id)initWithSFTPSession:(SFTPSession*)session;

- (void)downloadRemoteFile:(NSString*)remote_path 
		    toLocalRelativePath:(NSString*)local_path;

- (void)downloadRemoteFile:(NSString*)remote_path 
      remoteFileAttributes:(SFTPFileAttributes*)attributes
       toLocalRelativePath:(NSString*)local_path;

-(void)_raiseException:(NSString*)description;

@end
