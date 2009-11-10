//
//  FileThread.h
//  Briefcase
//
//  Created by Michael Taylor on 11/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HMWorkerThread : NSThread {
    NSRunLoop * myRunLoop;
}

@property (nonatomic,readonly) NSRunLoop * runLoop;

- (void)main;

@end
