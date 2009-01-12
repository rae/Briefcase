//
//  IconManager.h
//  Briefcase
//
//  Created by Michael Taylor on 13/06/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface IconManager : NSObject {
    
}

+(UIImage*)iconForFile:(NSString*)path smallIcon:(BOOL)want_small;
+(UIImage*)iconForExtension:(NSString*)extension smallIcon:(BOOL)want_small;
+(UIImage*)iconForFolderSmall:(BOOL)want_small;

+(UIImage*)iconForMacModel:(NSString*)model smallIcon:(BOOL)want_small;

+(UIImage*)iconForBonjour;
+(UIImage*)iconForGenericServer;
+(UIImage*)iconForiPhone;

@end
