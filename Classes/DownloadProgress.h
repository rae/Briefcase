//
//  DownloadProgress.h
//  Briefcase
//
//  Created by Michael Taylor on 30/01/09.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol DownloadProgress

@property (nonatomic,readonly)	NSUInteger  downloadedBytes;
@property (nonatomic,readonly)	NSUInteger  remainingBytes;

@end
