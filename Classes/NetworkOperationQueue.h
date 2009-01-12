//
//  NetworkOperationQueue.h
//  Briefcase
//
//  Created by Michael Taylor on 28/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkOperationQueue : NSOperationQueue {
    
}

+ (NetworkOperationQueue*)sharedQueue;

@end
