//
//  BlockingAlert.h
//  Briefcase
//
//  Created by Michael Taylor on 20/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlockingAlert : UIAlertView 
{
    NSCondition *   myCondition;
    NSInteger	    myAnswer;
}

- (NSInteger)showInMainThread;

@end
