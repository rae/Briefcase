//
//  ServerDelegate.m
//  Server Test
//
//  Created by Michael Taylor on 12/09/08.
//  Copyright 2008 Side Effects Software. All rights reserved.
//

#import "TestServerDelegate.h"

#import "SSHChannelFile.h"
#import "RegexKitLite.h"

static NSMutableDictionary * theFileHeaders = nil;

@implementation TestServerDelegate

- (BOOL)authenticateUser:(NSString*)user withPassword:(NSString*)password
{
    NSLog(@"Auth: %@ %@",user, password);
    return YES;
}

- (void)processCommand:(NSString*)command withChannel:(SSHChannelFile*)channel_file
{
    NSLog(@"Command: %@", command);
    
    NSString * cmd = [command stringByMatching:@"^\\S+"];
    NSRange arg_range = [command rangeOfRegex:@"\".*\""];
    
    NSString * arg = nil;
    if (arg_range.length >= 2)
    {
	arg_range.location += 1;
	arg_range.length -= 2;
	arg = [command substringWithRange:arg_range];
    }
    
    if ([cmd isEqualToString:@"get_free_space"])
    {
	long long free_space = 12345678;
	NSData * data = [NSData dataWithBytes:&free_space length:sizeof(free_space)];
	[channel_file writeData:data];
    }
    if ([cmd isEqualToString:@"file_header"])
    {
	if (!theFileHeaders)
	    theFileHeaders = [[NSMutableDictionary alloc] init];
	
	NSMutableData * data = [NSMutableData data];
	NSData * read = [channel_file readData];
	while (read)
	{
	    [data appendData:read];
	    read = [channel_file readData];
	}
	
	NSDictionary * dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	if (dictionary)
	    [theFileHeaders setObject:dictionary forKey:arg];
	NSLog(@"header data: %@", dictionary);	
    }
    if ([cmd isEqualToString:@"transmit_file"])
    {
	NSString * temp_dir = @"/tmp/";
	NSString * path = [temp_dir stringByAppendingPathComponent:arg];
	
	int open_flags = O_WRONLY|O_CREAT|O_APPEND|O_TRUNC;
	int file_descriptor = open([path UTF8String], open_flags, 0666);
	
	NSFileHandle * handle = [[NSFileHandle alloc] initWithFileDescriptor:file_descriptor];
	if (!handle) return;
	
	NSData * read = [channel_file readData];
	while (read)
	{
	    [handle writeData:read];
	    read = [channel_file readData];
	}
	[handle closeFile];
	[handle release];
    }
    
    [channel_file closeFile];
}

@end
