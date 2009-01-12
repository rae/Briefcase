//
//  main.m
//  Helpers
//
//  Created by Michael Taylor on 01/07/08.
//  Copyright 2008 Hey Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuickLook/QuickLook.h>

const int kIconSize = 57;
const int kPreviewSize = 128;

NSBitmapImageRep * scaleBitmap(NSBitmapImageRep * bitmap, NSSize size)
{
    NSBitmapImageRep *newBitmap = [[NSBitmapImageRep alloc]
				   initWithBitmapDataPlanes:NULL pixelsWide:size.width
				   pixelsHigh:size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
				   isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace
				   bitmapFormat:NSAlphaFirstBitmapFormat bytesPerRow:0 bitsPerPixel:32];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext
					  graphicsContextWithBitmapImageRep:newBitmap]];
    
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0,0,size.width,size.height));
    
    [bitmap drawInRect:NSMakeRect(0,0,size.width,size.height)];
    [NSGraphicsContext restoreGraphicsState];
    
    return [newBitmap autorelease];
}

NSBitmapImageRep * getPreview(NSString * path, NSSize size, BOOL as_icon)
{
    NSBitmapImageRep * result = nil;
    
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    if (!path || !fileURL) {
        return nil;
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:as_icon] 
                                                     forKey:(NSString *)kQLThumbnailOptionIconModeKey];
    CGImageRef ref = QLThumbnailImageCreate(kCFAllocatorDefault, 
                                            (CFURLRef)fileURL, 
                                            CGSizeMake(size.width, size.height),
                                            (CFDictionaryRef)dict);
    
    if (ref != NULL)
        result = [[NSBitmapImageRep alloc] initWithCGImage:ref];
    
    return result;
}

NSBitmapImageRep * getIcon(NSString * path)
{
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    
    if (icon) 
    {
	for (NSBitmapImageRep * rep in [icon representations])
	{
	    NSSize size = [rep  size];
	    
	    if (size.width == 128)
		// Scale the large icon down to 57x57
		return scaleBitmap(rep, NSMakeSize(kIconSize, kIconSize));
	}
    }
    return nil;
}

NSDictionary * iconAndPreviewForPath(NSString * path)
{
    NSData * data;
    
    NSSize icon_size = NSMakeSize(kIconSize, kIconSize);
    NSSize preview_size = NSMakeSize(kPreviewSize, kPreviewSize);
    
    NSBitmapImageRep * icon = getPreview(path, icon_size, YES);
    NSBitmapImageRep * preview = getPreview(path, preview_size, NO);
    
    if (!icon)
	icon = getIcon(path);
    
    NSMutableDictionary * data_dict = [NSMutableDictionary dictionaryWithCapacity:2];
    
    if (icon)
    {
	data = [icon representationUsingType:NSPNGFileType
				  properties:nil];
	[data_dict setObject:data forKey:@"icon"];
    }
    if (preview)
    {
	data = [preview representationUsingType:NSPNGFileType
				     properties:nil];
	[data_dict setObject:data forKey:@"preview"];
    }
    
    return [data_dict autorelease];
}

int main(int argc, char ** argv)
{
    NSData * data;
    
    if (argc == 2)
    {
	[NSApplication sharedApplication];
	[[NSAutoreleasePool alloc] init];
	
	NSString * path = [NSString stringWithUTF8String:argv[1]];
	
	data = [NSKeyedArchiver archivedDataWithRootObject:iconAndPreviewForPath(path)];
	     	
	fwrite([data bytes], [data length], 1, stdout);
    }
    
    return 0;
}