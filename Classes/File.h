//
//  File.h
//  Briefcase
//
//  Created by Michael Taylor on 06/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"

extern NSString * kFileDeleted;
extern NSString * kFileChanged;
extern NSString * kDirectoryDeleted;

@interface File : NSObject {
    sqlite3 *	myDatabase;
    
    NSString *	myLocalPath;
    NSNumber *	mySize;
    BOOL	myIsZipped;
    NSInteger   myDownloadComplete;
    
    long long	myLastViewLocation;
    NSArray *	myBookmarks;
    
    NSString *	myRemotePath;
    NSUInteger	myRemoteMode;
    NSString *	myRemoteHost;
    NSString *	myRemoteUsername;
    NSUInteger	myRemotePort;
    double	myRemoteCreationTime;
    double	myRemoteModifyTime;
    
    NSData *	myPreviewData;
    UIImage *	myPreviewImage;
    NSData *	myIconData;
    UIImage *	myIconImage;
    
    NSData *	myWebArchiveData;
    
    BOOL	myIsHydrated;
    BOOL	myIsDirty;
}

@property (copy,   nonatomic)		NSString * localPath;
@property (readonly, nonatomic) 	NSString * fileName;
@property (readonly, nonatomic)		NSString * fileExtension;
@property (readonly, nonatomic)		NSString * path;
@property (copy,   nonatomic)		NSNumber * size;
@property (assign, nonatomic)		BOOL	   isZipped;
@property (assign, nonatomic)		BOOL	   downloadComplete;

@property (assign, nonatomic)		long long  lastViewLocation;
@property (retain, nonatomic)		NSArray *  bookmarks;

@property (copy,   nonatomic)		NSString * remotePath;
@property (assign, nonatomic)		NSUInteger remoteMode;
@property (copy,   nonatomic)		NSString * remoteHost;
@property (copy,   nonatomic)		NSString * remoteUsername;
@property (assign, nonatomic)		NSUInteger remotePort;
@property (copy,   nonatomic)		NSDate *   remoteCreationTime;
@property (copy,   nonatomic)		NSDate *   remoteModificationTime;

@property (retain, nonatomic)		NSData  *  previewData;
@property (retain, nonatomic, readonly)	UIImage *  previewImage;
@property (retain, nonatomic)		NSData  *  iconData;
@property (retain, nonatomic, readonly)	UIImage *  iconImage;
@property (retain, nonatomic)		NSData *   webArchiveData;

@property (readonly, nonatomic)		NSString * contentsAsString;

+ (void)initializeFileDatabase;

+ (NSArray*)fileListAtLocalPath:(NSString*)path;
+ (NSArray*)searchForFilesMatching:(NSString*)fragment;
+ (NSArray*)incompleteFiles;
+ (void)deleteDirectoryAtLocalPath:(NSString*)path;
+ (void)deleteFileAtLocalPath:(NSString*)path;

+ (NSUInteger)totalSizeOfAllFiles;

+ (File*)getOrCreateFileWithLocalPath:(NSString*)local_path;
+ (File*)fileWithLocalPath:(NSString*)local_path;

- (id)initWithLocalPath:(NSString*)name;

- (void)delete;
- (void)hydrate;
- (void)save;
- (void)dehydrate;

- (NSComparisonResult)compareWithFile:(File*)other;


@end
