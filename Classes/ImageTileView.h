//
//  ImageTile.h
//  Briefcase
//
//  Created by Michael Taylor on 25/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageTileView;

@protocol ImageTileViewDelegate

- (void)imageTileDidDisplay:(ImageTileView*)view;

@end


@interface ImageTileView : UIImageView {
    BOOL			myDidDisplay;
    id <ImageTileViewDelegate>	myDelegate;
}

@property (readonly,nonatomic)	BOOL			    displayed;
@property (assign,nonatomic)	id <ImageTileViewDelegate>  delegate;

- (id)initWithFrame:(CGRect)frame image:(CGImageRef)image subRegion:(CGRect)region;

- (void)_extractRect:(CGRect)rect fromImage:(CGImageRef)image;

@end
