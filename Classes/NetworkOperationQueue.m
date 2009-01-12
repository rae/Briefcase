//
//  NetworkOperationQueue.m
//  Briefcase
//
//  Created by Michael Taylor on 28/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "NetworkOperationQueue.h"
#import "NetworkOperation.h"

static NetworkOperationQueue * theOperationQueue;

@implementation NetworkOperationQueue

+ (NetworkOperationQueue*)sharedQueue
{
    if (!theOperationQueue)
	theOperationQueue = [[NetworkOperationQueue alloc] init];
    return theOperationQueue;
}

- (id) init
{
    self = [super init];
    if (self != nil) {
	[self setMaxConcurrentOperationCount:4];
    }
    return self;
}


- (void)addOperation:(NSOperation *)operation
{
    [self performSelectorOnMainThread:@selector(_notifyAboutAdd:) 
			   withObject:operation 
			waitUntilDone:YES];
    [super addOperation:operation];
}

- (void)_notifyAboutAdd:(NSOperation*)operation
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kNetworkOperationQueued object:operation];
}

@end
