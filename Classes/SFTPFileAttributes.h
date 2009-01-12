//
//  SFTPFileAttributes.h
//  Briefcase
//
//  Created by Michael Taylor on 06/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "libssh2.h"
#import "libssh2_sftp.h"

@interface SFTPFileAttributes : NSObject {
    LIBSSH2_SFTP_ATTRIBUTES 	myAttributes;
    NSString *			myFilename;
    id				myUserData;
}

@property (readonly)		NSString *	    name;
@property (readonly)		BOOL		    isDir;
@property (readonly)		BOOL		    isLink;
@property (readonly)		unsigned long long  size;
@property (readonly)		NSUInteger	    permissions;
@property (readonly)		NSDate *	    modificationTime;
@property (nonatomic,retain)	id		    userData;

-(id)initWithAttributes:(LIBSSH2_SFTP_ATTRIBUTES*)attributes filename:(NSString*)name;

@end
