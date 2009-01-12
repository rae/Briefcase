//
//  CommandOperation.h
//  Briefcase
//
//  Created by Michael Taylor on 03/06/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SSHOperation.h"

@class Connection;

@interface SSHCommandOperation : SSHOperation 
{
    NSString *	myCommand;
    NSData *	myCommandInput;
}

@property (nonatomic,retain) NSData * commandInput;

-(id)initWithCommand:(NSString*)command connection:(Connection*)connection;
-(void)main;

@end
