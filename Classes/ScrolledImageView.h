//
//  ScrolledImageView.h
//  navtest
//
//  Created by Michael Taylor on 14/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageView;

@interface ScrolledImageView : UIScrollView <UIScrollViewDelegate>
{
    ImageView *	    myImageView;
    CGRect	    myOriginalViewFrame;
}

@property (assign,nonatomic)	CGImageRef  image;
@property (nonatomic,readonly)	CGSize	    imageSize;

- (void)adjustFrameWithBounce:(BOOL)allowsBounce;

- (void)viewBecameVisible;

@end
