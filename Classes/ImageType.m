//
//  ImageType.m
//  Briefcase
//
//  Created by Michael Taylor on 03/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ImageType.h"
#import "File.h"
#import "BriefcaseAppDelegate.h"
#import "ImageViewerController.h"
#import "FileAction.h"
#import "IconManager.h"

@implementation ImageType

- (id) init
{
    self = [super initWithWeight:10];
    if (self != nil) {
	myExtentions = [NSSet setWithObjects:
			@"jpg", 
			@"jpeg", 
			@"gif", 
			@"png", 
			@"bmp", 
			@"bmpf", 
			@"xbm",
			@"tif",
			@"tiff",
			nil];
	[myExtentions retain];
    }
    return self;
}

- (BOOL)isViewable
{
    return YES;
}

- (UIViewController*)viewControllerForFile:(File*)file
{	    
    ImageViewerController * image_view;
    image_view = [[ImageViewerController alloc] initWithFile:file];
    return [image_view autorelease];
}

- (NSArray*)getAttributesForFile:(File*)file
{
    NSArray * super_attributes = [super getAttributesForFile:file];
    
    // Start reading the image size in the background
    [self performSelectorInBackground:@selector(_readImageSize:) withObject:file.path];
    
    return super_attributes;
}

- (void)_readImageSize:(NSString*)path
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    UIImage * image = [UIImage imageWithContentsOfFile:path];
    
    if (image)
    {
	NSString * resolution_string = [NSString stringWithFormat:NSLocalizedString(@"%d by %d", @"Description of an image's size such as (1024 by 768)"),
					(NSInteger)image.size.width,
					(NSInteger)image.size.height];
	NSArray * resolution = [NSArray arrayWithObjects:NSLocalizedString(@"resolution", @"Label for information field that reports an images resolution"), 
				resolution_string,
				nil];
	[self performSelectorOnMainThread:@selector(_attributeNotify:) 
			       withObject:[resolution retain] 
			    waitUntilDone:NO];
    }
    
    [pool release];
}

- (void)_attributeNotify:(NSArray*)attribute
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:(NSString*)kFileAttributeAdded object:attribute];
    [attribute release];
}

- (UIImage*)getPreviewForFile:(File*)file
{
    UIImage * preview = file.previewImage;
    if (!preview)
	preview = [UIImage imageWithContentsOfFile:file.path];
    if (!preview)
	preview = file.iconImage;
    if (!preview)
	preview = [IconManager iconForFile:file.fileName smallIcon:NO];
    return preview;
}

#pragma mark Upload Actions

- (NSArray*)getUploadActionsForType
{
    FileAction * image_action;
    image_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Pictures", @"Pictures folder in the user's directory")
					    target:self 
					  selector:@selector(_uploadToImagesWithFile:connection:) 
				       requiresMac:YES];
    
    return [NSArray arrayWithObject:image_action];
}

- (NSArray*)_uploadToImagesWithFile:(File*)file connection:(BCConnection*)connection
{
    NSString * remote_path = @"Pictures";
    return [FileAction operationsForUploadOfFile:file toPath:remote_path];
}

#pragma mark File Specific Actions

- (NSArray*)getFileSpecificActions
{
    FileAction * view_action, * background_action, * iphoto_action;
    
    view_action = [FileAction fileActionWithTitle:NSLocalizedString(@"View Image On Mac", @"Label for file action that views an image on the connected Mac")
					   target:self 
					 selector:@selector(viewOnMac:connection:) 
				      requiresMac:YES];
    
    background_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Set as Desktop Background", @"Label for file action that sets an image as the desktop background on the remote Mac")
						 target:self 
					       selector:@selector(setBackgroundOnMac:connection:) 
					    requiresMac:YES];
    
    iphoto_action = [FileAction fileActionWithTitle:NSLocalizedString(@"Add Image to iPhoto Library", @"Label for file action that adds an image to the iPhoto library of the connected Mac")
					     target:self 
					   selector:@selector(addToiPhotoOnMac:connection:) 
					requiresMac:YES];
    
    return [NSArray arrayWithObjects:view_action, background_action, iphoto_action, nil];
}

- (NSArray*)viewOnMac:(File*)file connection:(BCConnection*)connection
{
    return [FileAction operationsForUploadOfFile:file withRemoteShellCommand:@"/usr/bin/open \"%@\""];
}

- (NSArray*)setBackgroundOnMac:(File*)file connection:(BCConnection*)connection
{
    return [FileAction operationsForUploadOfFile:file withRemoteShellCommand:@"osascript -e 'tell application \"Finder\"' -e 'set desktop picture to (POSIX file \"%@\")' -e 'end tell'"];
}

- (NSArray*)addToiPhotoOnMac:(File*)file connection:(BCConnection*)connection
{
    return [FileAction operationsForUploadOfFile:file withRemoteShellCommand:@"osascript -e 'tell application \"iPhoto\"' -e 'import from \"%@\"' -e 'end tell'"];
}


@end
