//
//  HashManager.m
//  Briefcase
//
//  Created by Michael Taylor on 22/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "HashManager.h"

NSString * kHostHashDictionaryKey = @"kHostHashDictionaryKey";

@implementation HashManager

+ (NSData*)hashForHost:(NSString*)host
{
    NSData * result = nil;
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary * host_dictionary = [defaults dictionaryForKey:kHostHashDictionaryKey];
    if (host_dictionary)
	result = [host_dictionary objectForKey:host];
    return result;
}

+ (void)setHashForHost:(NSString*)host hash:(NSData*)hash
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary * host_dictionary = [defaults dictionaryForKey:kHostHashDictionaryKey];
    NSMutableDictionary * new_dictionary;
    if (host_dictionary)
	new_dictionary = [NSMutableDictionary dictionaryWithDictionary:host_dictionary];
    else
	new_dictionary = [NSMutableDictionary dictionary];
    
    [new_dictionary setObject:hash forKey:host];
    [defaults setObject:new_dictionary forKey:kHostHashDictionaryKey];
    [defaults synchronize];
}

@end
