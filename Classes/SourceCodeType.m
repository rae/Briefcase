//
//  SourceCodeType.m
//  Briefcase
//
//  Created by Michael Taylor on 21/12/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SourceCodeType.h"
#import "DocumentViewController.h"
#import "File.h"
#import "BriefcaseAppDelegate.h"

@implementation SourceCodeType

- (id) init
{
    self = [super initWithWeight:10];
    if (self != nil) {
	myExtentions = [NSSet setWithObjects:
			@"h",
			@"hpp", 
			@"h++", 
			@"c", 
			@"cpp", 
			@"c++", 
			@"cc",
			@"m",
			@"mm",
			@"cs",  
			@"cyc", 
			@"java", 
			@"bsh", 
			@"bash", 
			@"sh",
			@"csh",
			@"tcsh",
			@"sh",
			@"zsh",
			@"cv",
			@"py",
			@"perl",
			@"pl",
			@"pm",
			@"rb",
			@"js",
			@"xml",
			@"xsl",
			@"cl",
			@"el",
			@"lisp",
			@"scm",
			@"lua",
			@"fs",
			@"ml",
			@"sql",
			@"proto",
			nil];
	[myExtentions retain];
    }
    return self;
}

- (UIViewController*)viewControllerForFile:(File*)file
{	 
    // Load the contents of the file
    NSString * contents = file.contentsAsString;
    
    if (!contents)
    {
	NSString * format = NSLocalizedString(@"Unable to open source file \"%@\" for display", "Message to user when loading a local file for display fails");
	
	UIAlertView * alert;
	alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"File Display Error", @"Title for error message telling the user that a file could not be displayed") 
					   message:[NSString stringWithFormat:format, [file.path lastPathComponent]]
					  delegate:nil 
				 cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button")
				 otherButtonTitles:nil];
	
	[alert release];
	return nil;
    }
    
    // Escape html characters "<", ">" and "&"
    NSMutableString * escaped_string = [NSMutableString stringWithString:contents];
    [escaped_string replaceOccurrencesOfString:@"&"
				    withString:@"&amp;" 
				       options:NSLiteralSearch 
					 range:NSMakeRange(0, [escaped_string length])];
    [escaped_string replaceOccurrencesOfString:@"<"
				    withString:@"&lt;" 
				       options:NSLiteralSearch 
					 range:NSMakeRange(0, [escaped_string length])];
    [escaped_string replaceOccurrencesOfString:@">"
				    withString:@"&gt;" 
				       options:NSLiteralSearch 
					 range:NSMakeRange(0, [escaped_string length])];
    
    // Load the template
    NSString * template_path = [[NSBundle mainBundle] pathForResource:@"SourceViewTemplate" 
							       ofType:@"html"];
    NSError * error = nil;
    NSMutableString * template_string = [[[NSMutableString alloc] initWithContentsOfFile:template_path
										encoding:NSUTF8StringEncoding 
										   error:&error] autorelease];
    [template_string replaceOccurrencesOfString:@"<SOURCE_CODE>"
				     withString:escaped_string
					options:NSLiteralSearch
					  range:NSMakeRange(0, [template_string length])];
    [template_string replaceOccurrencesOfString:@"<LANGUAGE>"
				     withString:file.fileExtension
					options:NSLiteralSearch 
					  range:NSMakeRange(0, [template_string length])];
    
    return [DocumentViewController documentViewControllerForFile:file withHTML:template_string];
}


- (BOOL)isViewable
{
    return YES;
}

@end
