//
//  FileInfoCell.h
//  Briefcase
//
//  Created by Michael Taylor on 23/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileInfoCell : UITableViewCell {
    NSArray *	    myAttributes;
    
    UIFont *	    myLabelFont;
    UIFont *	    myValueFont;
    
    UIColor *	    myLabelColor;
    UIColor *	    myValueColor;
    
    UIImageView *   myImageView;
}

@property (nonatomic,retain)	UIImage * icon;
@property (nonatomic,retain)	NSArray * attributes;
@property (nonatomic,readonly)	NSInteger preferredHeight; 

@end
