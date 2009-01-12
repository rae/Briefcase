//
//  SFTPSession.h
//  Briefcase
//
//  Created by Michael Taylor on 06/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "libssh2.h"
#import "libssh2_sftp.h"
#import "SFTPFile.h"
#import "SFTPFileAttributes.h"

@class SSHConnection;

@interface SFTPSession : NSObject {
    LIBSSH2_SFTP *  mySession;
    SSHConnection * myConnection;
}

@property (nonatomic,readonly) SSHConnection * connection;

-(id)initWithConnection:(SSHConnection*)connection;

-(NSArray*)readDirectory:(NSString*)path;

-(SFTPFile*)openRemoteFileForRead:(NSString*)path;
-(SFTPFile*)openRemoteFileForWrite:(NSString*)path;

-(SFTPFileAttributes*)statRemoteFile:(NSString*)path;

-(void)deleteFile:(NSString*)path;

-(NSString*)canonicalizePath:(NSString*)path;

-(void)_raiseSFTPException;

@end
