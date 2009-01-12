#!/usr/bin/pythonw
#
#  extract_icon.py
#  Briefcase
#
#  Created by Michael Taylor on 30/06/08.
#  Copyright (c) 2008 Hey Mac Software. All rights reserved.
#
import AppKit 
import sys, os, ctypes

AppKit.NSApplication.sharedApplication()

#from CoreGraphics import *

# Load QuickLook Framework
QuickLook = ctypes.cdll.LoadLibrary('/System/Library/Frameworks/QuickLook.framework/QuickLook')

class CGSize(ctypes.Structure):
     _fields_ = [("width", ctypes.c_float), ("height", ctypes.c_float)]
     
def imageWithPreviewOfFileAtPath(path, size, as_icon):
    file_url = AppKit.NSURL.fileURLWithPath_(path)
    
    if not path or not file_url:
        return None
    
    dict = AppKit.NSDictionary.dictionaryWithObject_forKey_(
		AppKit.NSNumber.numberWithBool_(as_icon), QuickLook.kQLThumbnailOptionIconModeKey)
    print dict
    
    dict = AppKit.CFDictionaryCreateMutable(AppKit.kCFAllocatorDefault, 0, None, None)
				
    ref = QuickLook.QLThumbnailImageCreate(AppKit.kCFAllocatorDefault, path, 
                                            CGSize(*size),
                                            None);
    return None

#    if (ref != NULL) {
#        # Take advantage of NSBitmapImageRep's -initWithCGImage: initializer, new in Leopard,
#        # which is a lot more efficient than copying pixel data into a brand new NSImage.
#        # Thanks to Troy Stephens @ Apple for pointing this new method out to me.
#        NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:ref];
#        NSImage *newImage = nil;
#        if (bitmapImageRep) {
#            newImage = [[NSImage alloc] initWithSize:[bitmapImageRep size]];
#            [newImage addRepresentation:bitmapImageRep];
#            [bitmapImageRep release];
#            
#            if (newImage) {
#                return [newImage autorelease];
#            }
#        }
#        CFRelease(ref);
#    } else {
#        # If we couldn't get a Quick Look preview, fall back on the file's Finder icon.
#        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
#        if (icon) {
#            [icon setSize:size];
#        }
#        return icon;
#    }
#    
#    return nil;

def main():
    #try:
	
	workspace = AppKit.NSWorkspace.sharedWorkspace()

	icon = imageWithPreviewOfFileAtPath(os.path.realpath(sys.argv[1]), (64, 64), True)
	if icon:
	    #icon = workspace.iconForFile_(os.path.realpath(sys.argv[1]))
	    icon.setSize_( (64, 64) )
	    data = icon.TIFFRepresentationUsingCompression_factor_(NSTIFFCompressionLZW, 0.0)
	    data.writeToFile_atomically_('/tmp/out.tif', False)
	
    #except:
	#sys.stderr.write('Error\n')
	#sys.exit(0)


if __name__ == '__main__':
	main()
