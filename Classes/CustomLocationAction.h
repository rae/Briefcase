//
//  CustomLocationAction.h
//  Briefcase
//
//  Created by Michael Taylor on 20/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FileAction.h"

@interface CustomLocationAction : FileAction 
{
    NSString * myCustomLocation;
}

@property (nonatomic,retain) NSString * location;

- (id)initWithCustomLocation:(NSString*)location;

@end
