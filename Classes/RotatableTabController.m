//
//  RotatableTabController.m
//  Briefcase
//
//  Created by Michael Taylor on 09-12-07.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import "RotatableTabController.h"

@implementation RotatableTabController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

@end
