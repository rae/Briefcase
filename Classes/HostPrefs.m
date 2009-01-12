//
//  HostPrefs.m
//  Briefcase
//
//  Created by Michael Taylor on 23/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "HostPrefs.h"

static NSString * kHostPreferencesKey = @"kHostPreferencesKey";

static NSString * kHostBrowseHomeDirKey = @"kHostBrowseHomeDirKey";
static NSString * kHostShowHiddenFiles = @"kHostShowHiddenFiles";
static NSString * kHostRemoteUploadLocations = @"kHostRemoteUploadLocations";

@implementation HostPrefs

+ (HostPrefs*)hostPrefsWithHostname:(NSString*)hostname
{
    return [[[HostPrefs alloc] initWithHostname:hostname] autorelease];
}

- (id)initWithHostname:(NSString*)hostname
{
    if (self = [super init])
    {
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary * host_dictionary = [defaults dictionaryForKey:kHostPreferencesKey];
	
	NSDictionary * host_prefs = nil;
	
	if (host_dictionary)
	    host_prefs = [host_dictionary objectForKey:hostname];
	else
	    // Initialize the host dictionary
	    [defaults setObject:[NSDictionary dictionary] forKey:kHostPreferencesKey];
	
	myHostname = [hostname retain];
	
	if (host_prefs)
	    myAttributes = [[NSMutableDictionary alloc] initWithDictionary:host_prefs];
	else
	    myAttributes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [myAttributes release];
    [myHostname release];
    [super dealloc];
}


- (void)save
{
    NSAssert(@"Null host name",myHostname);
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary * host_dictionary = [defaults dictionaryForKey:kHostPreferencesKey];
    
    if (host_dictionary)
    {
	NSMutableDictionary * new_host_dictionary;
	new_host_dictionary = [NSMutableDictionary dictionaryWithDictionary:host_dictionary];
	[new_host_dictionary setObject:myAttributes forKey:myHostname];
	[defaults setObject:new_host_dictionary forKey:kHostPreferencesKey];
    }
    else
    {
	NSDictionary * new_host_dictionary;
	new_host_dictionary = [NSDictionary dictionaryWithObject:myAttributes forKey:myHostname];
	[defaults setObject:new_host_dictionary forKey:kHostPreferencesKey];
    }
}

#pragma mark Properties

@synthesize hostname = myHostname;

- (BOOL)browseHomeDir
{
    NSNumber * bool_value = (NSNumber*)[myAttributes objectForKey:kHostBrowseHomeDirKey];
    if (bool_value)
	return [bool_value boolValue];
    
    return YES;
}

- (void)setBrowseHomeDir:(BOOL)browse_home_dir
{
    [myAttributes setObject:[NSNumber numberWithBool:browse_home_dir] forKey:kHostBrowseHomeDirKey];
    [self save];
}

- (BOOL)showHiddenFiles
{
    NSNumber * bool_value = (NSNumber*)[myAttributes objectForKey:kHostShowHiddenFiles];
    if (bool_value)
	return [bool_value boolValue];
    
    return NO;
}

- (void)setShowHiddenFiles:(BOOL)show_hidden
{
    [myAttributes setObject:[NSNumber numberWithBool:show_hidden] forKey:kHostShowHiddenFiles];
    [self save];
}

- (NSArray*)uploadLocations
{
    NSArray * locations = (NSArray*)[myAttributes objectForKey:kHostRemoteUploadLocations];
    if (locations)
	return locations;
    return [NSArray array];
}

- (void)setUploadLocations:(NSArray*)locations
{
    [myAttributes setObject:locations forKey:kHostRemoteUploadLocations];
    [self save];
}

@end
