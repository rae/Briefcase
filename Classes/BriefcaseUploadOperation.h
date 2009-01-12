//
//  BriefcaseUploadOperation.h
//  Briefcase
//
//  Created by Michael Taylor on 13/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NetworkOperation.h"
#import "BriefcaseChannel.h"

@class File;

@interface BriefcaseUploadOperation : NetworkOperation <BriefcaseChannelDelegate>
{
    File * myFile;
    BriefcaseConnection * myBriefcaseConnection;
    BriefcaseChannel *	  myChannel;
    NSCondition	*	  myDoneCondition;
    int			  myState;
    NSFileHandle *	  myFileHandle;
    long long		  myBytesRead;
    BOOL		  mySentCancel;
    BOOL		  myIsFinished;
}

- (id)initWithConnection:(BriefcaseConnection*)connection file:(File*)file;

@end
