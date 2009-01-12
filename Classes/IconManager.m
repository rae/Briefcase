//
//  IconManager.m
//  Briefcase
//
//  Created by Michael Taylor on 13/06/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "IconManager.h"
#import "RegexKitLite.h"
#import "Utilities.h"

static NSString * theIconPath = nil;
static NSMutableDictionary * theIconCache = nil;
static NSDictionary * theMacIconMapping = nil;

@implementation IconManager

+(void)initializeIconCache
{
    NSBundle * main_bundle = [NSBundle mainBundle];
    theIconPath = [main_bundle bundlePath];
    theIconPath = [theIconPath stringByAppendingPathComponent:@"icons"];
    [theIconPath retain];
    
    NSString * plist_path;
    
    theIconCache = [[NSMutableDictionary alloc] init];
    
    plist_path = [theIconPath stringByAppendingPathComponent:@"MacintoshIcons.dict"];
    theMacIconMapping = [[NSDictionary alloc] initWithContentsOfFile:plist_path];
}

+(UIImage*)iconForFile:(NSString*)path smallIcon:(BOOL)want_small
{    
    return [IconManager iconForExtension:[path pathExtension] smallIcon:want_small];
}

+(UIImage*)iconForExtension:(NSString*)extension smallIcon:(BOOL)want_small
{
    if (!theMacIconMapping)
	[self initializeIconCache];
	
    NSString * uti_string = [Utilities utiFromFileExtension:extension];
    if (!uti_string)
	uti_string = @"public.document";
    
    NSString * icon_file;
    if (want_small)
	icon_file = [NSString stringWithFormat:@"%@-small.png", uti_string];
    else
	icon_file = [NSString stringWithFormat:@"%@.png", uti_string];
	
    UIImage * icon = [theIconCache objectForKey:icon_file];
    if (!icon)
    {
	NSString * icon_path = [theIconPath stringByAppendingPathComponent:icon_file];
	icon = [UIImage imageWithContentsOfFile:icon_path];
	if (icon)
	    [theIconCache setObject:icon forKey:icon_file];
    }
    
    return icon;
}

+(UIImage*)iconForFolderSmall:(BOOL)want_small
{
    if (!theMacIconMapping)
	[self initializeIconCache];
        
    NSString * icon_file;
    if (want_small)
	icon_file = @"folder-small.png";
    else
	icon_file = @"folder.png";
    
    UIImage * icon = [theIconCache objectForKey:icon_file];
    if (!icon)
    {
	NSString * icon_path = [theIconPath stringByAppendingPathComponent:icon_file];
	icon = [UIImage imageWithContentsOfFile:icon_path];
	if (icon)
	    [theIconCache setObject:icon forKey:icon_file];
    }
    
    return icon;
}

+(UIImage*)iconForMacModel:(NSString*)model smallIcon:(BOOL)want_small
{
    if (!theMacIconMapping)
	[self initializeIconCache];
    
    // Check if there is an exact match in our mapping
    NSString * file_name = [theMacIconMapping objectForKey:model];
    
    if (!file_name)
    {
	// No exact match.  Try to find a looser match with
	// the name and the major version
	NSString * match = [model stringByMatching:@"^[^0-9]+[0-9]+"];
	file_name = [theMacIconMapping objectForKey:match];
    }
    
    if (!file_name)
    {
	// Still no exact match.  Try to just the machine name
	NSString * match = [model stringByMatching:@"^[^0-9]+"];
	file_name = [theMacIconMapping objectForKey:match];
    }
    
    if (want_small)
	file_name = [file_name stringByReplacingOccurrencesOfString:@".png" withString:@"_small.png"];
    
    if (file_name)
    {
	NSString * icon_path = [theIconPath stringByAppendingPathComponent:file_name];
	return [UIImage imageWithContentsOfFile:icon_path];
    }
    else
	return nil;
}

+(UIImage*)iconForBonjour
{
    if (!theMacIconMapping)
	[self initializeIconCache];
    
    NSString * icon_file = @"Bonjour-small.png";
    
    UIImage * icon = [theIconCache objectForKey:icon_file];
    if (!icon)
    {
	NSString * icon_path = [theIconPath stringByAppendingPathComponent:icon_file];
	icon = [UIImage imageWithContentsOfFile:icon_path];
	if (icon)
	    [theIconCache setObject:icon forKey:icon_file];
    }
    
    return icon;
}

+(UIImage*)iconForGenericServer
{
    if (!theMacIconMapping)
	[self initializeIconCache];
    
    NSString * icon_file = @"GenericNetworkIcon_small.png";
    
    UIImage * icon = [theIconCache objectForKey:icon_file];
    if (!icon)
    {
	NSString * icon_path = [theIconPath stringByAppendingPathComponent:icon_file];
	icon = [UIImage imageWithContentsOfFile:icon_path];
	if (icon)
	    [theIconCache setObject:icon forKey:icon_file];
    }
    
    return icon;
}

+(UIImage*)iconForiPhone
{
    if (!theMacIconMapping)
	[self initializeIconCache];
    
    NSString * icon_file = @"iPhone_small.png";
    
    UIImage * icon = [theIconCache objectForKey:icon_file];
    if (!icon)
    {
	NSString * icon_path = [theIconPath stringByAppendingPathComponent:icon_file];
	icon = [UIImage imageWithContentsOfFile:icon_path];
	if (icon)
	    [theIconCache setObject:icon forKey:icon_file];
    }
    
    return icon;
}

@end
