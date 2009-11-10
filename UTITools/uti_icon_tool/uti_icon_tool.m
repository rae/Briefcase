#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

NSString * kUTIListURL = @"http://developer.apple.com/documentation/Carbon/Conceptual/understanding_utis/utilist/chapter_4_section_1.html";

NSArray * getExtensionsForUTI(NSString * uti)
{
    NSArray * result = nil;
    
    NSDictionary * declaration = (NSDictionary*)UTTypeCopyDeclaration((CFStringRef)uti);
    
    NSDictionary * specs = [declaration objectForKey:@"UTTypeTagSpecification"];
    
    id extensions = [specs objectForKey:@"public.filename-extension"];
    
    if (extensions)
    {
	if ([extensions isKindOfClass:[NSArray class]])
	    result = extensions;
	else
	    result = [NSArray arrayWithObject:extensions];
    }
    
    return result;
}

NSArray * getUTIsFromFile(NSString * path)
{
    NSArray * file_contents = [[NSArray alloc] initWithContentsOfFile:path];
    NSMutableSet * set = [NSMutableSet setWithArray:file_contents];
    [file_contents release];
            
    [set addObjectsFromArray:(NSArray*)CGImageSourceCopyTypeIdentifiers()];

    // Add a few extras
    NSArray * extra_extensions = [NSArray arrayWithObjects:
				  @"pages",
				  @"numbers",
				  @"key",
				  @"app",
				  @"bundle",
				  @"dmg",
				  @"cdr",
				  @"iso",
				  @"pkg",
				  @"mpkg",
				  nil];
    for (NSString * extension in extra_extensions)
    {
	NSString * uti = (NSString*)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL);
	[set addObject:uti];
    }
    
    return [set allObjects];
}

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

void writeIconImagesForUTIs(NSArray * uti_array, NSString * path)
{
    NSString * filename, * icon_path;
    NSWorkspace * workspace = [NSWorkspace sharedWorkspace];
    
    
    for (NSString * item in uti_array)
    {
	NSImage * image = [workspace iconForFileType:item];
	if (image)
	{
	    for (NSBitmapImageRep * rep in [image representations])
	    {
		NSSize size = [rep  size];
		
		if (size.width == 32)
		{
		    // write the small icon
		    filename = [NSString stringWithFormat:@"%@-small.png", item];
		    icon_path = [path stringByAppendingPathComponent:filename];
		    NSData * data = [rep representationUsingType:NSPNGFileType
						      properties:nil];
		    [data writeToFile:icon_path atomically:NO];
		}
		if (size.width == 128)
		{
		    // Scale the large icon down to 57x57
		    filename = [NSString stringWithFormat:@"%@.png", item];
		    icon_path = [path stringByAppendingPathComponent:filename];
		    rep = scaleBitmap(rep, NSMakeSize(57, 57));
		    NSData * data = [rep representationUsingType:NSPNGFileType
						      properties:nil];
		    [data writeToFile:icon_path atomically:NO];
		    
		}
	    }
	}
	
    }
}

void writeExtensionMapping(NSArray * uti_array, NSString * path)
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    
    for (NSString * item in uti_array)
    {
	NSArray * extensions = getExtensionsForUTI(item);
	if (extensions && [extensions count] > 0)
	{
	    for (NSString * extension in extensions)
		[dict setObject:item forKey:extension];
	}
    }
    
    NSString * write_path = [path stringByAppendingPathComponent:@"extensionToUTIMapping.plist"];
    [dict writeToFile:write_path atomically:NO];
}

void writeUTIToMimeTypeMapping(NSArray * uti_array, NSString * path)
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    
    for (NSString * item in uti_array)
    {
	NSString * mime_type;
	mime_type = (NSString*)UTTypeCopyPreferredTagWithClass((CFStringRef)item, 
							       kUTTagClassMIMEType);
	if (mime_type) 
	{
	    [dict setObject:mime_type forKey:item];
	}
    }
    
    NSString * write_path = [path stringByAppendingPathComponent:@"utiToMimeTypeMapping.plist"];
    [dict writeToFile:write_path atomically:NO];
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSArray * uti_list = getUTIsFromFile([NSString stringWithUTF8String:argv[1]]);
    
    writeIconImagesForUTIs(uti_list, [NSString stringWithUTF8String:argv[3]]);
    
    writeExtensionMapping(uti_list, [NSString stringWithUTF8String:argv[2]]);
    writeUTIToMimeTypeMapping(uti_list, [NSString stringWithUTF8String:argv[2]]);
    
    [pool drain];
    return 0;
}
