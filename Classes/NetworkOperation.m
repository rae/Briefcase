//
//  NetworkOperation.m
//  Briefcase
//
//  Created by Michael Taylor on 31/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "NetworkOperation.h"


@implementation NetworkOperation

@dynamic title;
@dynamic description;
@synthesize progress = myProgress;
@synthesize reportErrors = myReportErrors;
@synthesize jobIdentifier = myJobIdentifier;

- (id)init
{
    if (self = [super init])
    {
	myReportErrors = YES;
	myProgress = 0.0;
	myTimer = nil;
    }
    return self;
}

- (void) dealloc
{
    [myError release];
    [super dealloc];
}


- (void)beginTask:(NSString*)task_name
{
    [task_name retain];
    [self performSelectorOnMainThread:@selector(_notifyBegin:) 
			   withObject:task_name
			waitUntilDone:NO];
}

- (void)updateProgress:(float)progress
{
    self.progress = progress;
}

- (void)endTask
{
    [self performSelectorOnMainThread:@selector(_notifyDoneWithResult:) 
			   withObject:nil
			waitUntilDone:YES];
}

- (void)endTaskWithResult:(id)result
{
    [result retain];
    [self performSelectorOnMainThread:@selector(_notifyDoneWithResult:) 
			   withObject:result
			waitUntilDone:YES];
}

- (void)endTaskWithError:(NSString*)error
{
    [error retain];
    [self performSelectorOnMainThread:@selector(_notifyDoneWithError:) 
			   withObject:error
			waitUntilDone:YES];
}

- (void)cancel
{    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kNetworkOperationCancelled
			  object:self
			userInfo:nil];
    [super cancel];
}

- (void)_notifyBegin:(NSString*)task_name
{
    NSDictionary * user_info;
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    user_info = [NSDictionary dictionaryWithObject:task_name forKey:@"name"];
    [center postNotificationName:kNetworkOperationBegan 
			  object:self
			userInfo:user_info];
    
    myTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 
					       target:self 
					     selector:@selector(_notifyProgress) 
					     userInfo:nil 
					      repeats:YES];
    [myTimer retain];
    
    [task_name release];
}

- (void)_notifyProgress
{
    NSDictionary * user_info;
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    user_info = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:self.progress]
					    forKey:@"progress"];
    [center postNotificationName:kNetworkOperationProgress
			  object:self
			userInfo:user_info];
}

- (void)_notifyDoneWithResult:(id)result
{
    NSDictionary * user_info = nil;
    
    if (result)
	user_info = [NSDictionary dictionaryWithObject:result forKey:@"result"];
    else
	user_info = [NSDictionary dictionary];
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kNetworkOperationEnd 
			  object:self
			userInfo:user_info];
    
    [result release];
     
    if (myTimer)
    {
	[myTimer invalidate];
	[myTimer release];
    }
}

- (void)_notifyDoneWithError:(NSString*)error
{
    NSDictionary * user_info = nil;
    
    myError = [error retain];
    
    NSString * message;
    message = [NSString stringWithFormat:NSLocalizedString(@"Done with error: %@", @"Log message when an operation ends with an error"),
	       error];
    [error release];
    user_info = [NSDictionary dictionaryWithObject:message forKey:@"error"];
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kNetworkOperationEnd 
			  object:self
			userInfo:user_info];
    
    if (myReportErrors)
	[self checkAndDisplayError];
    
    NSLog(message);
    
    if (myTimer)
    {
	[myTimer invalidate];
	[myTimer release];
    }
}

- (void)checkAndDisplayError
{
    if (!myError) return;
    
    // open an alert with just an OK button
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Operation Error", @"Title for dialogs that show error messages about failed network operations") 
//						    message:myError
//						   delegate:nil 
//					  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") 
//					  otherButtonTitles: nil];
//    [alert show];	
//    [alert release];
}

- (void)_raiseException:(NSString*)description
{
    NSException * exception = [NSException exceptionWithName:NSLocalizedString(@"Network Operation Error", @"Title for dialogs that show error messages about failed network operations")
						      reason:description
						    userInfo:nil];
    @throw exception;
}

@end
