//
//  UpgradeAlert.m
//  Briefcase
//
//  Created by Michael Taylor on 06/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "UpgradeAlert.h"

@implementation UpgradeAlert

- (id)initWithMessage:(NSString*)message
{
    self = [super initWithTitle:@"" 
			message:message 
		       delegate:nil 
	      cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") 
	      otherButtonTitles:nil];
    return self;
}

@end
