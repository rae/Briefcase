//
//  FileType.h
//  Briefcase
//
//  Created by Michael Taylor on 03/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * kFileAttributeAdded;

@class File;
@class Connection;

@interface FileType : NSObject {
    NSInteger	myWeight;
    NSSet *	myExtentions;
}

@property (nonatomic,assign) NSInteger weight;

+ (FileType*)findBestMatch:(File*)file;

- (id)initWithWeight:(NSInteger)weight;

- (BOOL)matchesFileType:(File*)file;
- (BOOL)isViewable;
- (void)viewFile:(File*)file;
- (NSArray*)getUploadActions;
- (NSArray*)getFileSpecificActions;
- (NSArray*)getBriefcaseActions;
- (NSArray*)getAttributesForFile:(File*)file;

- (UIImage*)getPreviewForFile:(File*)file;

// Used by subclasses
- (NSArray*)getUploadActionsForType;

@end
