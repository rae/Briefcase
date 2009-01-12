//
//  DownloadController.h
//  Briefcase
//
//  Created by Michael Taylor on 17/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NetworkOperation;

@interface DownloadController : NSObject {
}

+ (DownloadController*)sharedController;

- (id)init;

- (NetworkOperation*)downloadFile:(NSString*)path ofSize:(long long)bytes;

- (NetworkOperation*)zipAndDownloadDirectory:(NSString*)path;

- (NetworkOperation*)downloadDirectory:(NSString*)path;

- (void)resumeIncompleteDownloads;

@end
