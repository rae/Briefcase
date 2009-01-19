//
//  Utilities.m
//  Briefcase
//
//  Created by Michael Taylor on 17/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "Utilities.h"
#import <Foundation/Foundation.h>

@implementation Utilities

#define kDownloadsDirName  @"Downloads"

#define kGigabyte (2<<29)
#define kMegabyte (2<<19)
#define kKilobyte (2<<9)

#define kGiga 1000000000
#define kMega 1000000
#define kKilo 1000

static NSDictionary * theExtensionToUTIMapping = nil;
static NSDictionary * theUtiDescriptions = nil;
static NSSet * theBundleExtensions = nil;

+(NSString*) pathToDownloads
{
    NSArray * paths;
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
						NSUserDomainMask, YES);
    NSString * documents_directory = [paths objectAtIndex:0];
    NSString * dir_path = [documents_directory stringByAppendingPathComponent:kDownloadsDirName];
    
    // Make sure directory has been created
    NSFileManager * manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir_path])
	[manager createDirectoryAtPath:dir_path attributes:nil];
    
    return dir_path;
}

+(NSData*)getResourceData:(NSString*)name
{
    NSString * path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:name];
    return [NSData dataWithContentsOfFile:path];
}

+(NSString*)getResourcePath:(NSString*)name
{
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:name];    
}

+(NSString*)humanReadibleMemoryDescription:(unsigned long long)bytes
{
    NSString * format;
    NSNumber * value;
    
    NSNumberFormatter * length_formatter = [[NSNumberFormatter alloc] init];
    
    if (bytes > kGigabyte)
    {
	value = [NSNumber numberWithDouble:(double)bytes/(double)kGigabyte];
	if ([value doubleValue] > 10.0)
	   [length_formatter setMaximumFractionDigits:1];
	else
	    [length_formatter setMaximumFractionDigits:2];
	format = NSLocalizedString(@"%@ GB", @"Unit format string for displaying a number of gigabytes");
    }
    else if (bytes > kMegabyte)
    {
	value = [NSNumber numberWithDouble:(double)bytes/(double)kMegabyte];
	if ([value doubleValue] > 10.0)
	    [length_formatter setMaximumFractionDigits:1];
	else
	    [length_formatter setMaximumFractionDigits:2];
	format = NSLocalizedString(@"%@ MB", @"Unit format string for displaying a number of megabytes");
    }
    else if (bytes > kKilobyte)
    {
	value = [NSNumber numberWithDouble:(double)bytes/(double)kKilobyte];
	[length_formatter setMaximumFractionDigits:0];
	format = NSLocalizedString(@"%@ KB", @"Unit format string for displaying a number of kilobytes");
    }
    else
    {
	value = [NSNumber numberWithUnsignedInteger:bytes];
	[length_formatter setMaximumFractionDigits:0];
	format = NSLocalizedString(@"%@ B", @"Unit format string for displaying a number of bytes");
    }
    NSString * length_string;
    length_string = [length_formatter stringFromNumber:value];
    length_string = [NSString stringWithFormat:format, length_string];
    
    return length_string;
}

+(NSString*)humanReadibleFrequencyDescription:(unsigned long long)hertz
{
    NSString * format;
    NSNumber * value;
    
    NSNumberFormatter * length_formatter = [[NSNumberFormatter alloc] init];
    
    if (hertz > kGiga)
    {
	value = [NSNumber numberWithDouble:(double)hertz/(double)kGiga];
	[length_formatter setMaximumFractionDigits:2];
	format = NSLocalizedString(@"%@ GHz", @"Unit format string for displaying a number of gigahertz");
    }
    else if (hertz > kMega)
    {
	value = [NSNumber numberWithDouble:(double)hertz/(double)kMega];
	[length_formatter setMaximumFractionDigits:2];
	format = NSLocalizedString(@"%@ MHz", @"Unit format string for displaying a number of megahertz");
    }
    else if (hertz > kKilo)
    {
	value = [NSNumber numberWithDouble:(double)hertz/(double)kKilo];
	[length_formatter setMaximumFractionDigits:0];
	format = NSLocalizedString(@"%@ KHz", @"Unit format string for displaying a number of kilohertz");
    }
    else
    {
	value = [NSNumber numberWithUnsignedInteger:hertz];
	[length_formatter setMaximumFractionDigits:0];
	format = NSLocalizedString(@"%@ Hz", @"Unit format string for displaying a number of hertz");
    }
    NSString * length_string;
    length_string = [length_formatter stringFromNumber:value];
    length_string = [NSString stringWithFormat:format, length_string];
    
    return length_string;
}

+(NSString*)utiFromFileExtension:(NSString*)file_extension
{
    if (!theExtensionToUTIMapping)
    {
	NSBundle * main_bundle = [NSBundle mainBundle];
	NSString * plist_path = [[main_bundle bundlePath] stringByAppendingPathComponent:@"extensionToUTIMapping.plist"];
	theExtensionToUTIMapping = [[NSDictionary alloc] initWithContentsOfFile:plist_path];
    }
    
    return [theExtensionToUTIMapping objectForKey:file_extension];
}

+(NSString*)descriptionFromUTI:(NSString*)uti
{
    if (!theUtiDescriptions)
    {
	NSBundle * main_bundle = [NSBundle mainBundle];
	NSString * uti_description_path = [main_bundle pathForResource:@"utiDescriptions" ofType:@"plist"];
	theUtiDescriptions = [[NSDictionary alloc] initWithContentsOfFile:uti_description_path];
    }
    
    NSString * description = [theUtiDescriptions objectForKey:uti];
    if (!description)
	description = @"";
    return description;
}

+(BOOL)isBundle:(NSString*)path
{
    if (!theBundleExtensions)
	theBundleExtensions = [[NSSet alloc] initWithObjects:
			       @"pages",
			       @"numbers",
			       @"key",
			       @"bundle",
			       @"app",
			       @"rtfd",
			       @"vmx",
			       @"vdesigner",
			       @"vpdoc",
			       @"workflow",
			       @"ofocus",
			       @"oo3",
			       nil];
    
    return [theBundleExtensions containsObject:[[path pathExtension] lowercaseString]];
}

+(UIImage*)scaleImage:(UIImage*)image toMaxSize:(CGSize)size
{
    if (image.size.width < size.width && image.size.height < size.height)
	return image;
    
    CGSize result_size;
    
    if (image.size.width / size.width > image.size.height / size.height)
    {
	// constrained by width
	result_size.width = size.width;
	result_size.height = size.height * (image.size.height / image.size.width);
    }
    else 
    {
	// constrained by height
	result_size.height = size.height;
	result_size.width = size.width * (image.size.width / image.size.height);
    }
    
    UIGraphicsBeginImageContext(result_size);
    
    [image drawInRect:CGRectMake(0.0, 0.0, result_size.width, result_size.height)];
     
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
     
    UIGraphicsEndImageContext();
    
    return result;
}

@end

#pragma mark LongPoint functions

NSString * NSStringFromLongPoint(LongPoint point)
{
    return [NSString stringWithFormat:@"{%qi, %qi}", point.x, point.y];
}

LongPoint LongPointFromNSString(NSString * string)
{
    LongPoint result = {0, 0};
    
    NSCharacterSet * skip_chars = [NSCharacterSet characterSetWithCharactersInString:@"{,} \t"];
    NSScanner * scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:skip_chars];
    
    [scanner scanLongLong:&(result.x)];
    [scanner scanLongLong:&(result.y)];
    
    return result;
}

LongPoint LongPointMake(long long x, long long y)
{
    LongPoint result = {x, y};
    return result;
}

LongPoint LongPointZero = {0, 0};

#pragma mark Other Utility Functions

// Calculate the scale to fit a rect of inner_size within a rect of outer_size
double scaleFactorForRectWithinRect(CGSize outer_size, CGSize inner_size)
{
    double width_ratio = (double)outer_size.width / (double)inner_size.width;
    double height_ratio = (double)outer_size.height / (double)inner_size.height;
    
    return MIN(width_ratio, height_ratio);
}



