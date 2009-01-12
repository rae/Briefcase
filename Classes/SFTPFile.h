//
//  SFTPFile.h
//  Briefcase
//
//  Created by Michael Taylor on 17/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "libssh2.h"
#import "libssh2_sftp.h"

@protocol SFTPFileDelegate

- (void)transferProgress:(double)progress;

@end


@interface SFTPFile : NSObject {
    LIBSSH2_SFTP_HANDLE *   myFile;
    id <SFTPFileDelegate>   myDelegate;
    NSMutableData *	    myReturnData;
}

- (id)initWithFile:(LIBSSH2_SFTP_HANDLE*)file;

- (void)closeFile;
- (void)writeData:(NSData*)data;
- (NSData*) readDataOfLength:(NSUInteger)length;
- (void)seekToFileOffset:(NSInteger)offset;
- (NSUInteger)position;
- (void)seekToBeginningOfFile;

- (void)_raiseException:(NSString*)message;
@end
