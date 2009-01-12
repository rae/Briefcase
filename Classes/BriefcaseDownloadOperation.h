//
//  BriefcaseDownloadOperation.h
//  Briefcase
//
//  Created by Michael Taylor on 14/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NetworkOperation.h"

@class File;
@class BriefcaseConnection;

@interface BriefcaseDownloadOperation : NetworkOperation
{
    File *		    myFile;
    NSFileHandle *	    myFileHandle;
    
    NSString *		    myFilename;
    long long		    mySize;
    NSData *		    myIconData;
    NSData *		    myPreviewData;
    BOOL		    myIsZipped;
    
    long long		    myBytesWritten;
    
    NSCondition *	    myCondition;
    
    BOOL		    myLocalUserCancelled;
    
    BriefcaseConnection *   myBriefcaseConnection;
}

@property (nonatomic,retain) BriefcaseConnection * connection;

+ (BOOL)okToDownload:(NSDictionary*)header;

- (id)initWithFileHeader:(NSDictionary*)header;

- (void)addData:(NSData*)data;
- (void)done;
- (void)cancel;

@end
