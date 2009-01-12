//
//  FileViewController.m
//  Briefcase
//
//  Created by Michael Taylor on 02/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "FileViewController.h"
#import "File.h"

static FileViewController * theFileViewController = nil;

@implementation FileViewController

+ (FileViewController*)sharedController
{
    if (!theFileViewController)
	theFileViewController = [[FileViewController alloc] init];
    return theFileViewController;
}


- (void)viewFile:(File*)path
{
    
}

@end
