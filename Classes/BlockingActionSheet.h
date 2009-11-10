//
//  BlockingActionSheet.h
//  Briefcase
//
//  Created by Michael Taylor on 09-09-17.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlockingActionSheet : UIActionSheet 
{
    NSCondition *   myCondition;
    NSInteger	    myAnswer;
}

- (NSInteger)showInMainThreadFromTabBar:(UITabBar*)tab_bar;

@end
