//
//  SSHConnection.h
//  Briefcase
//
//  Created by Michael Taylor on 08/04/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BCConnection.h"
#import "BCConnectionDelegate.h"
#import "libssh2.h"

@class SFTPSession;
@class KeychainItem;
@class SSHChannelFile;
@class KeychainKeyPair;

extern NSString * kSSHKeyPairGenerationCompleted;

@interface SSHConnection : BCConnection {
    LIBSSH2_SESSION *	mySession;
    NSData *		myExpectedHash;
    SFTPSession *	mySFTPSession;
}

@property (nonatomic,retain)	NSData * expectedHash;
@property (nonatomic,readonly)	LIBSSH2_SESSION * session;

+ (NSLock*)sshLock;

// SSH Key Management

+ (BOOL)hasSSHKeyPair;
+ (void)ensureSSHKeyPairCreated;
+ (void)regenerateSSHKeyPair;
+ (KeychainKeyPair*)sshKeyPair;
+ (void)setAutoInstallPublicKey:(BOOL)auto_install;

- (BOOL)connect;
- (void)loginWithKeychainItem:(KeychainItem*)item;

- (void)disconnect;

- (SFTPSession*)getSFTPSession;
 
- (NSData*)executeCommand:(NSString*)command;
- (NSData*)executeCommand:(NSString*)command withInput:(NSData*)input;
- (NSData*)executeCommand:(NSString*)command withInputFile:(NSString*)path;
- (SSHChannelFile*)openExecChannelWithCommand:(NSString*)command;

@end
