//
//  BriefcaseMessage.h
//  Briefcase
//
//  Created by Michael Taylor on 28/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Security/Security.h>

enum BriefcaseMessageType
{
    kInvalidMessageType,
    kConnectionRequest,
    kConnectionAllowed,
    kRequestResponse,
    kRequestDenied,
    kFreeSpaceRequest,
    kFreeSpaceResponse,
    kFileHeader,
    kFileHeaderResponse,
    kFileData,
    kFileDataResponse,
    kFileDone,
    kFileDoneResponse,
    kFileCancelled,
    kFileCancelledResponse
};

enum BriefcaseMessageState
{
    kDefault,
    kReadingHeader,
    kReadingData,
    kTransmissionComplete
};

enum BriefcaseMessageTag 
{
    kInvalidTag = 0,
    kChannelTag,
    kServerTag,
    kBaseChannelTag
};

struct HeaderData
{
    NSSwappedDouble channelID;
    NSUInteger	    payloadSize;
    uint8_t	    messageType;
    uint8_t	    encryped;
};

#define kHeaderDataSize sizeof(struct HeaderData)

@interface BriefcaseMessage : NSObject 
{
    enum BriefcaseMessageType	myMessageType;
    NSData *			myPayload;
    long			myTag;
    double			myChannelID;
    enum BriefcaseMessageState	myTransmitState;
    NSCondition	*		myTransmitCondition;
    NSError *			myTransmitError;
    BOOL			myIsEncrypted;
}

@property (nonatomic,assign)	enum BriefcaseMessageType   type;
@property (nonatomic,retain)	NSData *		    headerData;
@property (nonatomic,retain)	NSData *		    payloadData;
@property (nonatomic,retain)	NSDictionary *		    payloadDictionary;
@property (nonatomic,retain)	NSString *		    payloadString;
@property (nonatomic,retain)	NSNumber *		    payloadNumber;
@property (nonatomic,readonly)	BOOL			    payloadEncrypted;

@property (nonatomic,assign)	long			    tag;
@property (nonatomic,assign)	double			    channelID;

@property (nonatomic,assign)	enum BriefcaseMessageState  transmitState;
@property (nonatomic,retain)	NSCondition *		    transmitCondition;
@property (nonatomic,retain)	NSError *		    transmitError;

+ (BriefcaseMessage*)messageWithType:(enum BriefcaseMessageType)type;
+ (NSUInteger)payloadSizeFromHeader:(NSData*)data;

- (id)initWithMessageType:(enum BriefcaseMessageType)type;

- (void)encryptWithPublicKey:(NSData*)key;
- (void)decryptWithPrivateKey:(NSData*)key;
- (void)encryptWithSymmetricKey:(NSData*)key;
- (void)decryptWithSymmetricKey:(NSData*)key;

@end
