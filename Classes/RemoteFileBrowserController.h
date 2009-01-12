//
//  RemoteFileBrowserController.h
//  Briefcase
//
//  Created by Michael Taylor on 06/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DirectoryViewController;
@class SFTPSession;
@class NotConnectedController;
@class NoIPhoneDownloadController;

@interface RemoteFileBrowserController : NSObject {
    UINavigationController *	myNavigationController;
    DirectoryViewController *	myRootDirectoryViewController;
    SFTPSession *		mySFTPSession;
    NSMutableDictionary *	myDirectoryCache;
    NSOperationQueue *		myOperationQueue;
    NotConnectedController *	myNotConnectedView;
    NoIPhoneDownloadController* myNoDownloadsView;
}

@property (readonly) UINavigationController * navigationController;
@property (retain,nonatomic) SFTPSession * sftpSession;

+ (RemoteFileBrowserController*)sharedController;

- (id)init;

- (void)loadView:(DirectoryViewController*) fromPath:(NSString*)path;

- (void)pushViewForPath:(NSString*)path;
- (void)resetToRoot;

- (void)updateDirectoryCacheForPath:(NSString*)path;
- (void)addDirectoryToCache:(NSString*)path withItems:(NSArray*)items;
- (void)directoryUpdateFailedForPath:(NSString*)path;

- (void)_updateViews;

@end
