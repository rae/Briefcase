//
//  MovieType.m
//  Briefcase
//
//  Created by Michael Taylor on 08/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "MovieType.h"
#import "FileAction.h"

@implementation MovieType

- (id) init
{
    self = [super initWithWeight:10];
    if (self != nil) {
	myExtentions = [NSSet setWithObjects:
			@"m4v",
			@"mp4",
			@"mov",
			@"3gp",
			nil];
	[myExtentions retain];
    }
    return self;
}

- (NSArray*)getUploadActionsForType
{
    FileAction * movie_action;
    
    movie_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Movies", @"Movies folder in the user's directory")
					    target:self 
					  selector:@selector(_uploadToMoviesWithFile:connection:) 
				       requiresMac:YES];
    
    return [NSArray arrayWithObject:movie_action];
}

- (NSArray*)_uploadToMoviesWithFile:(File*)file connection:(BCConnection*)connection
{
    NSString * remote_path = @"Movies";
    return [FileAction operationsForUploadOfFile:file toPath:remote_path];
}

@end
