//
//  SFTPFileAttributes.m
//  Briefcase
//
//  Created by Michael Taylor on 06/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SFTPFileAttributes.h"
#import "SSHConnection.h"
#import <sys/stat.h>


@implementation SFTPFileAttributes

@dynamic isDir;
@synthesize userData = myUserData;
@synthesize name = myFilename;

-(id)initWithAttributes:(LIBSSH2_SFTP_ATTRIBUTES*)attributes filename:(NSString*)name
{
    myAttributes = *attributes;
    myFilename = [name retain];
    return [super init];
}

- (void)dealloc {
    [myFilename release];
    [super dealloc];
}

- (BOOL)isDir
{ 
    // TODO: this is different for ssh v4 protocol
    return S_ISDIR(myAttributes.permissions);
}

- (BOOL)isLink
{ 
    // TODO: this is different for ssh v4 protocol
    return S_ISLNK(myAttributes.permissions);
}

- (unsigned long long)size
{
    return myAttributes.filesize;
}

- (NSUInteger)permissions
{
    return myAttributes.permissions;
}

- (NSDate*)modificationTime
{
    double seconds_since_epoch = (double)myAttributes.mtime;
    return [NSDate dateWithTimeIntervalSince1970:seconds_since_epoch];
}

@end
