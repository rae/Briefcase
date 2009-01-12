//
//  NetworkOperation.h
//  Briefcase
//
//  Created by Michael Taylor on 31/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNetworkOperationQueued	    @"Network Operation Queued"
#define kNetworkOperationBegan	    @"Network Operation Began"
#define kNetworkOperationProgress   @"Network Operation Progress"
#define kNetworkOperationEnd	    @"Network Operation End"
#define kNetworkOperationCancelled  @"Network Operation Cancelled"


@interface NetworkOperation : NSOperation {
    NSString *	myError;
    BOOL	myReportErrors;
    NSString *	myJobIdentifier;
    float	myProgress;
    
    NSTimer *	myTimer;
}

@property (nonatomic,readonly) NSString * title;
@property (nonatomic,readonly) NSString * description;
@property (assign)	       float	  progress;
@property (nonatomic,assign)   BOOL	  reportErrors;
@property (nonatomic,retain)   NSString * jobIdentifier;

-(void)beginTask:(NSString*)task_name;
-(void)updateProgress:(float)progress;
-(void)endTask;
-(void)endTaskWithResult:(id)result;
-(void)endTaskWithError:(NSString*)error;

-(void)checkAndDisplayError;

-(void)_raiseException:(NSString*)description;

@end
