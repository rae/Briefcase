//
//  UTIViewController.m
//  UTIGrabber
//
//  Created by Michael Taylor on 10/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "UTIWindowController.h"
#import <ApplicationServices/ApplicationServices.h>
#import <CoreServices/CoreServices.h>

@implementation UTIWindowController

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
    
    // Extra UTI's
    [set addObject:@"public.folder"];
    
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

- (NSDictionary*)getExtensionsAndDescriptions:(NSArray*)array
{
    NSMutableDictionary * dict = [[NSMutableDictionary dictionary] retain];
    
    for (NSString * uti in array)
    {
	NSDictionary * declaration = (NSDictionary*)UTTypeCopyDeclaration((CFStringRef)uti);
	
	NSString * description = (NSString*)UTTypeCopyDescription((CFStringRef)uti);
	
	if (![uti isEqualToString:@"public.folder"])
	{
	    NSDictionary * specs = [declaration objectForKey:@"UTTypeTagSpecification"];
	    id extensions = [specs objectForKey:@"public.filename-extension"];
	    
	    if (!extensions) 
		continue;
	    
	    if ([extensions isKindOfClass:[NSArray class]] && [extensions count] == 0)
		continue;
	}
	
	[dict setObject:description forKey:uti];	
    }
    return dict;
}

- (void)doLoadUTIList:(id)sender
{
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    
    [panel runModalForTypes:[NSArray arrayWithObject:@"plist"]];
    NSArray * files = [panel filenames];
    
    NSArray * array = getUTIsFromFile([files objectAtIndex:0]);
    
    myDict = [[self getExtensionsAndDescriptions:array] retain];
    
    [myDict writeToFile:@"/tmp/foo.txt" atomically:NO];
    
    NSLog(@"Extensions: %@", myDict);
        
    [myTextView setRichText:NO];
    [myTextView setString:[myDict descriptionWithLocale:nil]];
}

- (void)doSaveMapping:(id)sender
{
    NSSavePanel * panel = [NSSavePanel savePanel];
    [panel runModal];
    
    [myDict writeToFile:[panel filename] atomically:NO];
}
    

@end
