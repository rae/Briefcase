//
//  HashManager.h
//  Briefcase
//
//  Created by Michael Taylor on 22/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HashManager : NSObject 
{

}

+ (NSData*)hashForHost:(NSString*)host;
+ (void)setHashForHost:(NSString*)host hash:(NSData*)hash;

@end
