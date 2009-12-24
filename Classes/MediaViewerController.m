//
//  MediaViewerController.m
//  Briefcase
//
//  Created by Michael Taylor on 15/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "MediaViewerController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "BriefcaseAppDelegate.h"

@implementation MediaViewerController

- (id)initWithPath:(NSString*)path
{
    if (self = [super initWithNibName:@"Loading" bundle:nil]) {
	NSURL * media_url = [NSURL fileURLWithPath:path];
	myMoviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:media_url];

	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(moviePlayBackDidFinish) 
		       name:MPMoviePlayerPlaybackDidFinishNotification 
		     object:nil];
    }
    return self;
}

- (void)viewDidLoad 
{
    [myMoviePlayer play];
}

- (void)dealloc {
    [myMoviePlayer release];
    [super dealloc];
}

- (void)moviePlayBackDidFinish
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
