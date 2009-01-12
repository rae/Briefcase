//
//  DirectoryReadOperation.h
//  Briefcase
//
//  Created by Michael Taylor on 14/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DirectoryReadOperation : NSOperation {
    NSString * myPath;
}

- (id)initWithPath:(NSString*)path;
- (void)main;

@end
