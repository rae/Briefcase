//
//  HostPrefs.h
//  Briefcase
//
//  Created by Michael Taylor on 23/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HostPrefs : NSObject 
{
    NSString *		    myHostname;
    NSMutableDictionary *   myAttributes;
}

@property (nonatomic,readonly)	NSString *  hostname;
@property (nonatomic,assign)	BOOL	    browseHomeDir;
@property (nonatomic,assign)	BOOL	    showHiddenFiles;
@property (nonatomic,copy)	NSArray *   uploadLocations;

+ (HostPrefs*)hostPrefsWithHostname:(NSString*)hostname;

- (id)initWithHostname:(NSString*)hostname;

- (void)save;

@end
