//
//  ConnectedController.h
//  Briefcase
//
//  Created by Michael Taylor on 08/06/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SystemInfoController;

@interface ConnectedController : UIViewController <UIAlertViewDelegate> {
    SystemInfoController * mySystemInfoController;
    
    NSString *			myConnectingTitle;
    NSString *			myConnectedTitle;
    BOOL			myIsBriefcaseConnection;
    
    IBOutlet UIButton *		myDisconnectButton;
}

@property (retain,nonatomic) NSString *			hostName;
@property (assign)	     BOOL			isBriefcaseConnection;

- (id)init;

- (IBAction)disconnect:(id)sender;
- (IBAction)showSystemInformation:(id)sender;
- (IBAction)clearKeychain:(id)sender;

@end
