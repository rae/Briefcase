//
//  HMCrashHandler.m
//  Briefcase
//
//  Created by Michael Taylor on 09-11-10.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import "HMCrashHandler.h"
#import <CrashReporter/CrashReporter.h>
#import "BCConnectionManager.h"
#import "CJSONSerializer.h"
#import "HMBuild.h"

#define TestServer 0

#if TestServer
static NSString * kPingURL          = @"http://192.168.1.100:8000/ping/";
static NSString * kStackTraceURL    = @"http://192.168.1.100:8000/crash/";
#else
static NSString * kPingURL          = @"http://appstats.heymacdev.com/ping/";
static NSString * kStackTraceURL    = @"http://appstats.heymacdev.com/crash/";
#endif

@interface HMCrashHandler (Private)

- (void)uploadPendingCrashReport;
- (BOOL)isPirated;
- (void)postDictionary:(NSDictionary*)dictionary toURL:(NSString*)url;
- (void)_pingServer;
- (NSString*)stackTraceForReport:(PLCrashReport*)report;

@end

static HMCrashHandler * theCrashHandler = nil;

@implementation HMCrashHandler

+ (HMCrashHandler*)sharedHandler
{
    if (!theCrashHandler) 
        theCrashHandler = [[HMCrashHandler alloc] init];
    
    return theCrashHandler;
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        NSError * error = nil;
        PLCrashReporter * reporter = [PLCrashReporter sharedReporter];
        [reporter enableCrashReporterAndReturnError:&error];
        if (error)
            NSLog(@"%@", error);
    }
    return self;
}


- (void)pingServer
{
    [self performSelectorInBackground:@selector(_pingServer) withObject:nil];
}

- (void)handlePendingCrashReports
{
    if (![[PLCrashReporter sharedReporter] hasPendingCrashReport])
        return;
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Crash Detected",@"Title to message telling the user that a previous crash has been detected")
                                                        message:NSLocalizedString(@"A previous crash has been detected.  Would you like to send the report to us to help fix this in future versions?",@"Message to user asking for permission to upload a crash report")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                              otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil
                              ];
    [alertView show];
    [alertView autorelease];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.firstOtherButtonIndex == buttonIndex) {
        [self performSelectorInBackground:@selector(_uploadPendingCrashReport)
                               withObject:nil];
    } else {
        [[PLCrashReporter sharedReporter] purgePendingCrashReport];
    }
}

- (NSString*)stackTraceForReport:(PLCrashReport*)report 
{
    NSMutableString* stackTrace = [[NSMutableString alloc] init];
    
    for (PLCrashReportThreadInfo * thread in report.threads) {
        if (thread.crashed) {
            [stackTrace appendFormat:@"Crashed Thread:  %d\n", thread.threadNumber];
            break;
        }
    }
    
    [stackTrace appendFormat:@"\n"];
    
    /* Threads */
    for (PLCrashReportThreadInfo *thread in report.threads) {
        if (thread.crashed)
            [stackTrace appendFormat:@"Thread %d Crashed:\n", thread.threadNumber];
        else
            [stackTrace appendFormat:@"Thread %d:\n", thread.threadNumber];
        for (NSUInteger frame_idx = 0; frame_idx < [thread.stackFrames count]; frame_idx++) {
            PLCrashReportStackFrameInfo *frameInfo = [thread.stackFrames objectAtIndex: frame_idx];
            PLCrashReportBinaryImageInfo *imageInfo;
            
            /* Base image address containing instrumention pointer, offset of the IP from that base
             * address, and the associated image name */
            uint64_t baseAddress = 0x0;
            uint64_t pcOffset = 0x0;
            const char *imageName = "\?\?\?";
            
            imageInfo = [report imageForAddress: frameInfo.instructionPointer];
            if (imageInfo != nil) {
                imageName = [[imageInfo.imageName lastPathComponent] UTF8String];
                baseAddress = imageInfo.imageBaseAddress;
                pcOffset = frameInfo.instructionPointer - imageInfo.imageBaseAddress;
            }
            
            [stackTrace appendFormat:@"%-4d%-36s0x%08" PRIx64 " 0x%" PRIx64 " + %" PRId64 "\n", 
             frame_idx, imageName, frameInfo.instructionPointer, baseAddress, pcOffset];
        }
        [stackTrace appendFormat:@"\n"];
    }
    
    /* Images */
    [stackTrace appendFormat:@"Binary Images:\n"];
    NSMutableDictionary* imageDumps = [[NSMutableDictionary alloc] init];
    for (PLCrashReportBinaryImageInfo *imageInfo in report.images) {
        NSString *uuid;
        /* Fetch the UUID if it exists */
        if (imageInfo.hasImageUUID)
            uuid = imageInfo.imageUUID;
        else
            uuid = @"???";
        
        /* base_address - terminating_address file_name identifier (<version>) <uuid> file_path */
        NSString* line = [NSString stringWithFormat:@"0x%" PRIx64 " - 0x%" PRIx64 "  %s \?\?\? (\?\?\?) <%s> %s\n",
                          imageInfo.imageBaseAddress,
                          imageInfo.imageBaseAddress + imageInfo.imageSize,
                          [[imageInfo.imageName lastPathComponent] UTF8String],
                          [uuid UTF8String],
                          [imageInfo.imageName UTF8String]];
        [imageDumps setObject:line forKey:[NSNumber numberWithUnsignedInt:imageInfo.imageBaseAddress]];
    }
    
    NSArray* sortedArray = [[imageDumps allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for(NSNumber* key in sortedArray) {
        [stackTrace appendString:[imageDumps objectForKey:key]];
    }
    
    [imageDumps release];
    
    return [stackTrace autorelease];
}

- (BOOL)isPirated
{
#ifdef NDEBUG
    // Check the size of the Info.plist file against the size when built
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * info_plist_path = [[NSBundle mainBundle] pathForResource:@"Info" 
                                                                 ofType:@"plist"];
    NSDictionary * attributes = [manager attributesOfItemAtPath:info_plist_path
                                                          error:nil];
    NSInteger size = [[attributes objectForKey:NSFileSize] intValue];
    if (size != HM_SIZE_OF_INFO_PLIST)
        return YES;
    
    // Check for the signer identity
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    if ([info objectForKey: @"SignerIdentity"] != nil)
        return YES;

    NSString * info_string = [NSString stringWithContentsOfFile:info_plist_path 
                                                       encoding:NSUTF8StringEncoding 
                                                          error:NULL];
    // Check for ascii plist
    if ([info_string rangeOfString:@"</plist>"].location != NSNotFound)
        return YES;
#endif
    
    return NO;
}

- (void)_pingServer
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    BCConnectionManager * manager = [BCConnectionManager sharedManager];
    
    if(manager.networkAvailable) 
    {
        NSMutableDictionary* ping_dictionary = [[NSMutableDictionary alloc] init];
        UIDevice * device = [UIDevice currentDevice];
        NSDictionary * info_dictionary = [[NSBundle mainBundle] infoDictionary];
        
        [ping_dictionary setObject:[info_dictionary objectForKey:(id)kCFBundleNameKey] forKey:@"application"];
        [ping_dictionary setObject:[info_dictionary objectForKey:(id)kCFBundleVersionKey] forKey:@"appVersion"];
        [ping_dictionary setObject:device.uniqueIdentifier forKey:@"udid"];
        [ping_dictionary setObject:device.model forKey:@"model"];
        [ping_dictionary setObject:device.systemName forKey:@"systemName"];
        [ping_dictionary setObject:device.systemVersion forKey:@"systemVersion"];
        [ping_dictionary setObject:[NSNumber numberWithBool:manager.wifiAvailable] forKey:@"wifi"];
        [ping_dictionary setObject:[NSNumber numberWithBool:[self isPirated]] forKey:@"pirated"];
        
        [self postDictionary:ping_dictionary toURL:kPingURL];
        
        [ping_dictionary release];
    }
    
    [pool release];
}

- (void)_uploadPendingCrashReport
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    PLCrashReporter* crashReporter = [PLCrashReporter sharedReporter];
    NSData* crashData;
    NSError* error;
    
    @try {
        // Try loading the crash report
        crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
        if (crashData == nil) 
            [NSException raise:@"Crash Report Error"
                        format:@"Could not load crash report: %@", error];
        
        // We could send the report from here, but we'll just print out
        // some debugging info instead
        PLCrashReport* report = [[[PLCrashReport alloc] initWithData: crashData error: &error] autorelease];
        
        if (report == nil) {
            [NSException raise:@"Crash Report Error"
                        format:@"Could not parse crash report"];
        }
        
        NSString* systemName;
        switch (report.systemInfo.operatingSystem) {
            case PLCrashReportOperatingSystemMacOSX:
                systemName = @"Mac OS X";
                break;
            case PLCrashReportOperatingSystemiPhoneOS:
                systemName = @"iPhone OS";
                break;
            case PLCrashReportOperatingSystemiPhoneSimulator:
                systemName = @"iPhone Simulator";
                break;
            default:
                systemName = @"Unknown";
        }
        
        NSString* codeType;
        switch (report.systemInfo.architecture) {
            case PLCrashReportArchitectureARM:
                codeType = @"ARM (Native)";
                break;
            case PLCrashReportArchitectureX86_32:
                codeType = @"X86";
                break;
            case PLCrashReportArchitectureX86_64:
                codeType = @"X86-64";
                break;
            default:
                codeType = @"Unknown";
                break;
        }
        
        NSMutableDictionary* report_dictionary = [[NSMutableDictionary alloc] init];
        UIDevice * device = [UIDevice currentDevice];
        NSDictionary * info_dictionary = [[NSBundle mainBundle] infoDictionary];
        
        [report_dictionary setObject:[info_dictionary objectForKey:(id)kCFBundleNameKey] forKey:@"application"];
        [report_dictionary setObject:[self stackTraceForReport:report] forKey:@"stackTrace"];
        [report_dictionary setObject:[info_dictionary objectForKey:(id)kCFBundleVersionKey] forKey:@"appVersion"];
        [report_dictionary setObject:device.uniqueIdentifier forKey:@"udid"];
        [report_dictionary setObject:report.signalInfo.code forKey:@"signalCode"];
        [report_dictionary setObject:report.signalInfo.name forKey:@"signalName"];
        [report_dictionary setObject:[NSString stringWithFormat:@"0x%" PRIx64 "", report.signalInfo.address] forKey:@"exceptionAddress"];
        [report_dictionary setObject:[NSString stringWithFormat:@"%@ %@", systemName, report.systemInfo.operatingSystemVersion] forKey:@"systemVersion"];
        [report_dictionary setObject:codeType forKey:@"arch"];
        [report_dictionary setObject:[report.systemInfo.timestamp description] forKey:@"timestamp"];
        
        [self postDictionary:report_dictionary toURL:kStackTraceURL];
        
        [report_dictionary release];
        
    }
    @catch (NSException * e) {
        NSLog(@"Exception thrown: %@", e);
    }
    @finally {
        [[PLCrashReporter sharedReporter] purgePendingCrashReport];
        [pool release];
    }
}

- (void)postDictionary:(NSDictionary*)dictionary toURL:(NSString*)url
{
    NSString *json_string = [[CJSONSerializer serializer] serializeObject:dictionary];
    NSData *post_data = [json_string dataUsingEncoding:NSUTF8StringEncoding];
    NSString *post_length = [NSString stringWithFormat:@"%d", [post_data length]];
    
    NSMutableURLRequest * request = [[[NSMutableURLRequest alloc] init] autorelease];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:post_length forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:post_data];
    
    NSURLResponse * response = nil;
    NSError * error = nil;
    [NSURLConnection sendSynchronousRequest:request 
                          returningResponse:&response 
                                      error:&error];
}

@end
