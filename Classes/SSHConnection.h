//
//  SSHConnection.h
//  Briefcase
//
//  Created by Michael Taylor on 08/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "Connection.h"
#import "ConnectionDelegate.h"
#import "libssh2.h"

@class SFTPSession;
@class KeychainItem;
@class SSHChannelFile;

@interface SSHConnection : Connection {
    LIBSSH2_SESSION *	mySession;
    NSData *		myExpectedHash;
    SFTPSession *	mySFTPSession;
}

@property (nonatomic,retain)	NSData * expectedHash;
@property (nonatomic,readonly)	LIBSSH2_SESSION * session;

+ (NSLock*)sshLock;

- (BOOL)connect;
- (void)loginWithKeychainItem:(KeychainItem*)item;

- (void)disconnect;

- (SFTPSession*)getSFTPSession;
 
- (NSData*)executeCommand:(NSString*)command;
- (NSData*)executeCommand:(NSString*)command withInput:(NSData*)input;
- (NSData*)executeCommand:(NSString*)command withInputFile:(NSString*)path;
- (SSHChannelFile*)openExecChannelWithCommand:(NSString*)command;

// Private

- (void)_raiseException:(NSString*)message;
- (void)_connect;
- (void)_didDisconnect;
- (LIBSSH2_CHANNEL*)_newChannel;

@end
