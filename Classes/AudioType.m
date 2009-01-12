//
//  AudioType.m
//  Briefcase
//
//  Created by Michael Taylor on 08/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "AudioType.h"
#import "FileAction.h"

@implementation AudioType

- (id) init
{
    self = [super initWithWeight:10];
    if (self != nil) {
	myExtentions = [NSSet setWithObjects:
			@"m4a",
			@"mp3",
			@"wav",
			@"aif",
			@"aiff",
			@"aa",
			@"caf",
			nil];
	[myExtentions retain];
    }
    return self;
}

- (NSArray*)getUploadActionsForType
{
    FileAction * audio_action;
    
    audio_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Music", @"Music folder in the user's directory")						target:self 
					      selector:@selector(_uploadToMusicWithFile:connection:) 
					   requiresMac:YES];
    
    return [NSArray arrayWithObject:audio_action];
}

- (NSArray*)_uploadToMusicWithFile:(File*)file connection:(Connection*)connection
{
    NSString * remote_path = @"Music";
    return [FileAction operationsForUploadOfFile:file toPath:remote_path];
}

@end
