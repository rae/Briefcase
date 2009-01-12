//
//  BriefcaseChannel.h
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BriefcaseMessage;

@protocol BriefcaseChannelDelegate

- (void)channelResponseRecieved:(BriefcaseMessage*)message;

@end

@class BriefcaseConnection;

@interface BriefcaseChannel : NSObject 
{
    double				myChannelID;
    BriefcaseConnection *		myConnection;
    id <BriefcaseChannelDelegate>	myDelegate;
}

@property (nonatomic,readonly)	double channelID;

- (id)initWithConnection:(BriefcaseConnection*)connection 
		delegate:(id <BriefcaseChannelDelegate>)delegate;

- (void)sendMessage:(BriefcaseMessage*)message;

- (void)processMessage:(BriefcaseMessage*)message;

@end
