//
//  ImageView.h
//  Briefcase
//
//  Created by Michael Taylor on 23/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageTileView.h"

#define kMaxTileSize (1024 * 1024)

extern NSString * kImageViewImageDisplayed;

@class File;

@interface ImageView : UIView <ImageTileViewDelegate> 
{
    CGImageRef		myImage;
    UIView *		myTileView;
    float		myMaxScale;
    
    NSMutableArray *	myPendingTiles;
}

@property (assign,nonatomic)	CGImageRef  image;
@property (readonly,nonatomic)	CGSize	    imageSize;
@property (readonly,nonatomic)  float	    maxScale;

- (void)displayTiles;

@end
