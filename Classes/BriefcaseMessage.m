//
//  BriefcaseMessage.m
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BriefcaseMessage.h"
#import "NSData+Sec.h"

//#define NO_ENCRYPTION

unsigned int theNextTag = 1;
NSLock * theTagLock = nil;

@implementation BriefcaseMessage

+ (BriefcaseMessage*)messageWithType:(enum BriefcaseMessageType)type
{
    if (!theTagLock)
	theTagLock = [[NSLock alloc] init];
    
    return [[[BriefcaseMessage  alloc] initWithMessageType:type] autorelease];
}

+ (NSUInteger)payloadSizeFromHeader:(NSData*)data
{
    struct HeaderData * header_data = (struct HeaderData*)[data bytes];
    return NSSwapBigIntToHost(header_data->payloadSize);
}

- (id)initWithMessageType:(enum BriefcaseMessageType)type
{   
    self = [super init];
    
    if (self != nil) {
	myMessageType = type;
	myTransmitState = kDefault;
	[theTagLock lock];
	myTag = theNextTag++;
	[theTagLock unlock];
	myChannelID = 0;
	myIsEncrypted = NO;
    }
    return self;
}

- (void) dealloc
{
    [myPayload release];
    [myTransmitCondition release];
    [super dealloc];
}

- (void)encryptWithPublicKey:(NSData*)key
{
#ifndef NO_ENCRYPTION
    NSAssert(!myIsEncrypted,@"Already encrypted!");
    self.payloadData = [self.payloadData encryptWithPublicKey:key];
    myIsEncrypted = YES;
#endif
}

- (void)decryptWithPrivateKey:(NSData*)key
{
#ifndef NO_ENCRYPTION
    NSAssert(myIsEncrypted,@"Not encrypted!");
    self.payloadData = [self.payloadData decryptWithPrivateKey:key];
    myIsEncrypted = NO;
#endif
}
- (void)encryptWithSymmetricKey:(NSData*)key
{
#ifndef NO_ENCRYPTION
    NSAssert(!myIsEncrypted,@"Already encrypted!");
    self.payloadData = [self.payloadData encryptWithSymmetricKey:key];
    myIsEncrypted = YES;
#endif
}

- (void)decryptWithSymmetricKey:(NSData*)key
{
#ifndef NO_ENCRYPTION
    NSAssert(myIsEncrypted,@"Not encrypted!");
    self.payloadData = [self.payloadData decryptWithSymmetricKey:key];
    myIsEncrypted = NO;
#endif
}

#pragma mark Properties

@synthesize type = myMessageType;
@synthesize payloadData = myPayload;
@synthesize tag = myTag;
@synthesize channelID = myChannelID;
@synthesize transmitState = myTransmitState;
@synthesize transmitCondition = myTransmitCondition;
@synthesize transmitError = myTransmitError;
@synthesize payloadEncrypted = myIsEncrypted;

- (NSData*)headerData
{
    struct HeaderData header_data;
    
    NSUInteger payload_size = 0;
    if (myPayload)
	payload_size = [myPayload length];    
        
    header_data.messageType = myMessageType;
    header_data.encryped = (uint8_t)myIsEncrypted;
    header_data.channelID = NSSwapHostDoubleToBig(myChannelID);
    header_data.payloadSize = NSSwapHostIntToBig(payload_size);
    
    return [NSData dataWithBytes:&header_data length:kHeaderDataSize];
}

- (void)setHeaderData:(NSData*)data
{
    NSAssert([data length] == kHeaderDataSize,@"Invalid header slipped through");
        
    struct HeaderData * header_data = (struct HeaderData*)[data bytes];
    myMessageType = header_data->messageType;
    myIsEncrypted = header_data->encryped;
    myChannelID = NSSwapBigDoubleToHost(header_data->channelID);
}

- (NSDictionary*)payloadDictionary
{
    NSDictionary * result = nil;
    
    @try
    {
	if (myPayload)
	    result = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:myPayload];
    }
    @catch(NSException * exception)
    {
	NSLog(@"Exception caught\n  %@", exception);
    }
    
    return result;
}

- (void)setPayloadDictionary:(NSDictionary*)dictionary
{
    [myPayload release];
    self.payloadData = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
}

- (NSString*)payloadString
{
    NSString * result = nil;
    
    if (myPayload)
	result = [[[NSString alloc] initWithData:myPayload encoding:NSUTF8StringEncoding] autorelease]; 
    
    return result;
}

- (void)setPayloadString:(NSString*)string
{
    [myPayload release];
    myPayload = [[string dataUsingEncoding:NSUTF8StringEncoding] retain];
}

- (NSNumber*)payloadNumber
{
    NSNumber * result = nil;
    
    if (myPayload)
    {
	NSDictionary * payload_dictionary = self.payloadDictionary;
	if (payload_dictionary)
	    result = [payload_dictionary objectForKey:@"value"];
    }
    
    return result;
}

- (void)setPayloadNumber:(NSNumber*)number
{
    [myPayload release];
    
    NSDictionary * payload_dictionary = [NSDictionary dictionaryWithObject:number forKey:@"value"];
    self.payloadDictionary = payload_dictionary;
}


@end
