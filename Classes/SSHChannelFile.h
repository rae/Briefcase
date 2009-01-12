//
//  SSHChannelFile.h
//  Briefcase
//
//  Created by Michael Taylor on 13/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "libssh2.h"

@interface SSHChannelFile : NSObject {
    LIBSSH2_CHANNEL *   myChannel;
    NSMutableData *	myBuffer;
}

- (id)initWithChannel:(LIBSSH2_CHANNEL*)channel;

- (void)closeFile;
- (void)writeData:(NSData*)data;
- (NSData*) readData;

// Private

- (void)_raiseException:(NSString*)message;

@end
