//
//  SystemInfoManager.m
//  Briefcase
//
//  Created by Michael Taylor on 01/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SystemInformation.h"
#import "ConnectionController.h"
#import "Utilities.h"

static NSDictionary * theMacTypesDictionary;

@implementation SystemInformation

@synthesize isConnected = myIsConnected;
@dynamic isConnectedToMac;
@synthesize darwinVersion = myDarwinVersion;
@synthesize macModel = myModel;

-(id)initWithConnection:(SSHConnection*)connection
{
    if (self = [super init]) {
	myConnection = [connection retain];
	mySystemData = nil;
	myDarwinVersion = -1;
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(connectionEstablished:) 
		       name:kConnectionEstablished 
		     object:myConnection];
	
	[center addObserver:self 
		   selector:@selector(connectionTerminated:) 
		       name:kConnectionTerminated
		     object:myConnection];
    }
    return self;
}

-(void)dealloc
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
    
    [myConnection release];
    [super dealloc];
}

-(BOOL)isConnectedToMac
{
    return (myDarwinVersion > 0);
}

-(NSString*)tempDir
{
    if (myTempDir) 
	return myTempDir;
    else
	return @"/tmp/";
}

-(NSUInteger)itemCount
{
    if (mySystemData)
	return [mySystemData count];
    else
	return 0;
}

-(NSString*)descriptionForItemAtIndex:(NSUInteger)index
{
    if (!mySystemData) return @"";
    
    return [[mySystemData objectAtIndex:index] objectAtIndex:0];
}

-(NSString*)valueForItemAtIndex:(NSUInteger)index
{
    if (!mySystemData) return @"";
    
    return [[mySystemData objectAtIndex:index] objectAtIndex:1];
}

-(void)connectionEstablished:(NSNotification*)notification
{
    // Start a query in the background to get information from
    // the server
    [self performSelectorInBackground:@selector(_queryServerInfo:) withObject:[notification object]];
    
    myIsConnected = YES;
}

-(void)connectionTerminated:(NSNotification*)notification
{    
    myIsConnected = NO;
    if (mySystemData)
    {
	[mySystemData release];
	mySystemData = nil;
    }
    myDarwinVersion = -1;
    [self _notifyObservers];
}

-(void)_queryServerInfo:(SSHConnection*)connection
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    if (!connection)
	return;
    
    // First try uname to identify the machine
    @try
    {
	NSData * result = [connection executeCommand:@"uname"];    
    
	if (result)
	{
	    NSString * result_string = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
	    NSArray * components = [result_string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	    if ([components count] > 0)
	    {
		NSLog(@"uname: %@",result_string);
		result_string = [components objectAtIndex:0];
		if ([result_string isEqualToString:@"Darwin"])
		    [self _queryOSXInfoOnConnection:connection];
	    }
	}
	
	// Store the system data with the connection
	connection.userData = [self retain];
	
	[self performSelectorOnMainThread:@selector(_notifyObservers) 
			       withObject:nil 
			    waitUntilDone:NO];
    }
    @catch(NSException*)
    {
	NSLog(@"Error querying system information on remote machine");
    }
    
    [pool release];
}
    
-(void)_notifyObservers
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

    [center postNotificationName:kSystemInfoChanged 
			  object:self
			userInfo:nil];
}

-(void)_addOSXHostName:(NSDictionary*)dictionary
{
    NSString * value = [dictionary objectForKey:@"kern.hostname"];
    
    if (value)
    {
	NSArray * pair = [NSArray arrayWithObjects:NSLocalizedString(@"Computer Name", @"System information label for computer name"), value, nil];

	@synchronized(self)
	{
	    [mySystemData addObject:pair]; 
	}
    }
}

-(void)_addOSXVersion:(NSDictionary*)dictionary
{
    NSString * value = [dictionary objectForKey:@"kern.osrelease"];
    
    if (value)
    {
	NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
	
	NSArray * parts = [value componentsSeparatedByString:@"."];
	NSNumber * major = [formatter numberFromString:[parts objectAtIndex:0]];
	NSNumber * minor = [formatter numberFromString:[parts objectAtIndex:1]];
	
	int major_value = [major intValue] - 4;
	
	NSString * os_version = [NSString stringWithFormat:@"OS X 10.%d.%@",
				 major_value, minor];
	
	NSArray * pair = [NSArray arrayWithObjects:NSLocalizedString(@"OS Version", @"System information label for the version of the operating system"), os_version, nil];
	
	@synchronized(self)
	{
	    [mySystemData addObject:pair]; 
	}
	
	NSString * darwinMajorMinor = [NSString stringWithFormat:@"%@.%@", 
				       major, minor];
	NSNumber * darwinNumber = [formatter numberFromString:darwinMajorMinor];
	myDarwinVersion = [darwinNumber doubleValue];
	
	[formatter release];
    }
}

-(void)_addOSXMemorySize:(NSDictionary*)dictionary
{
    NSString * value = [dictionary objectForKey:@"hw.memsize"];
    
    if (value)
    {
	NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
	
	NSNumber * size_number = [formatter numberFromString:value];
	NSString * size_string = [Utilities humanReadibleMemoryDescription:[size_number longLongValue]];
	NSArray * pair = [NSArray arrayWithObjects:NSLocalizedString(@"Memory Size", @"System information label for the amount of memory in the computer"), size_string, nil];
	
	@synchronized(self)
	{
	    [mySystemData addObject:pair]; 
	}
	
	[formatter release];
    }
}

-(void)_addOSXModel:(NSDictionary*)dictionary
{
    NSString * value = [dictionary objectForKey:@"hw.model"];
    
    if (value)
    {
	myModel = [value retain];
	
	if (!theMacTypesDictionary)
	{
	    NSString * mac_dict_path = [Utilities getResourcePath:@"Macintoshes.dict"];
	    theMacTypesDictionary = [[NSDictionary alloc] initWithContentsOfFile:mac_dict_path];
	}
	
	NSString * model_desc = [theMacTypesDictionary objectForKey:myModel];
	
	if (model_desc)
	{
	    NSArray * pair = [NSArray arrayWithObjects:NSLocalizedString(@"Computer Type", @"System information label for the type of computer (eg iMac)"), model_desc, nil];
	    
	    @synchronized(self)
	    {
		[mySystemData addObject:pair]; 
	    }
	    
	}
    }
}

-(void)_addOSXCPUCount:(NSDictionary*)dictionary
{
    NSString * value = [dictionary objectForKey:@"hw.ncpu"];
    
    if (value)
    {
	NSArray * pair = [NSArray arrayWithObjects:NSLocalizedString(@"CPU Cores", @"System information label for the number of core the CPU(s) in the computer have"), value, nil];
	    
	@synchronized(self)
	{
	    [mySystemData addObject:pair]; 
	}
    }
}

-(void)_addOSXCPUFreq:(NSDictionary*)dictionary
{
    NSString * value = [dictionary objectForKey:@"hw.cpufrequency"];
    
    if (value)
    {
	NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
	
	NSNumber * size_number = [formatter numberFromString:value];
	NSString * size_string = [Utilities humanReadibleFrequencyDescription:[size_number longLongValue]];
	NSArray * pair = [NSArray arrayWithObjects:NSLocalizedString(@"CPU Frequency", @"System information label for the frequence of the CPU(s) (eg 3GHz)"), size_string, nil];
	
	@synchronized(self)
	{
	    [mySystemData addObject:pair]; 
	}
	
	[formatter release];
    }
}

-(void)_addOSXBusFreq:(NSDictionary*)dictionary
{
    NSString * value = [dictionary objectForKey:@"hw.busfrequency"];
    
    if (value)
    {
	NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
	
	NSNumber * size_number = [formatter numberFromString:value];
	NSString * size_string = [Utilities humanReadibleFrequencyDescription:[size_number longLongValue]];
	NSArray * pair = [NSArray arrayWithObjects:NSLocalizedString(@"Bus Frequency", @"System information label for the frequency of the bus (eg 1.3GHz"), size_string, nil];
	
	@synchronized(self)
	{
	    [mySystemData addObject:pair]; 
	}
	
	[formatter release];
    }
}

-(void)_queryOSXInfoOnConnection:(SSHConnection*)connection
{
    // Read inforation about the machine using the sysctl command
    NSData * data = [connection executeCommand:@"sysctl kern.osrelease hw.memsize kern.hostname hw.model hw.ncpu hw.cpufrequency hw.busfrequency"];
    
    NSString * result = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding];        
    NSArray * lines = [result componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableDictionary * system_data = [[NSMutableDictionary alloc] init];
    
    NSString * line;
    for (line in lines)
    {
	NSArray * parts = [line componentsSeparatedByString:@": "];
	if ([parts count] != 2)
	    parts = [line componentsSeparatedByString:@" = "];
	if ([parts count] != 2)
	    // Couldn't parse
	    continue;
	[system_data setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
    }
    
    @synchronized(self)
    {
	if (mySystemData)
	    [mySystemData release];
	mySystemData = [[NSMutableArray alloc] initWithCapacity:[system_data count]];
    }
    
    [self _addOSXHostName:system_data]; 
    [self _addOSXModel:system_data];     
    [self _addOSXVersion:system_data];
    [self _addOSXCPUCount:system_data];
    [self _addOSXCPUFreq:system_data];
    [self _addOSXBusFreq:system_data];
    [self _addOSXMemorySize:system_data]; 
    
    // Read more information by injecting our binary
    NSData * packed_data = nil;
    NSData * system_helper = [Utilities getResourceData:@"system_info_extract.py.bz2"];
    NSString * command = @"bzip2 -d -c|python -c \"import sys;eval(compile(sys.stdin.read(),'<stdin>','exec'))\"";
    @try 
    {
	packed_data = [myConnection executeCommand:command withInput:system_helper];
    }
    @catch (NSException*) 
    {
	NSLog(@"Could not information for remote file");
    }
    if (packed_data)
    {
	NSDictionary * dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:packed_data];
	myTempDir = [[dictionary objectForKey:@"temp dir"] retain];
    }
    
}



@end
