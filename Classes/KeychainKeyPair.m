//
//  KeychainKeyPair.m
//  Briefcase
//
//  Created by Michael Taylor on 02/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "KeychainKeyPair.h"

#define kKeySize 1024

#import "SSCrypto.h"

@interface KeychainKeyPair (Private)

+ (void)_dumpAllKeys;
+ (void)_deleteAllKeys;
- (void)_raiseException:(NSString*)message;

@end

@implementation KeychainKeyPair

@synthesize publicKey	= myPublicKey;
@synthesize privateKey	= myPrivateKey;

#if ! TARGET_IPHONE_SIMULATOR

- (id)initWithName:(NSString*)name
{
    self = [super init];
    if (self != nil) {
	OSStatus status;
	    
	NSDictionary * search_result;
	NSMutableDictionary * parameters;
	
//	[KeychainKeyPair _deleteAllKeys];
//	[KeychainKeyPair _dumpAllKeys];
	
	parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		      (id)kSecClassKey,		    kSecClass,
		      [NSNumber numberWithInt:2],   kSecMatchLimit,
		      (id)kCFBooleanTrue,	    kSecReturnAttributes,
		      (id)kCFBooleanTrue,	    kSecReturnData,
		      name,			    kSecAttrLabel,
		      nil];
	
	status = SecItemCopyMatching((CFDictionaryRef)parameters, 
				     (CFTypeRef *)&search_result);
		
	if (status != errSecSuccess || !search_result || [search_result count] < 2)
	{
	    // We need to generate the key pair
	    myPrivateKey = [[SSCrypto generateRSAPrivateKeyWithLength:kKeySize] retain];
	    myPublicKey = [[SSCrypto generateRSAPublicKeyFromPrivateKey:self.privateKey] retain];
	    
	    NSMutableDictionary * attributes;
	    attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			  (id)kSecClassKey,		     kSecClass,
			  (id)kSecAttrKeyClassPublic,	     kSecAttrKeyClass,
			  [NSNumber numberWithInt:kKeySize], kSecAttrKeySizeInBits,
			  [NSNumber numberWithInt:kKeySize], kSecAttrEffectiveKeySize,
			  self.publicKey,		     kSecValueData,
			  name,				     kSecAttrLabel,
			  nil];
	    
	    status = SecItemAdd((CFDictionaryRef)attributes, NULL);
	    
	    if (status != errSecSuccess)
		[self _raiseException:NSLocalizedString(@"Could not add public key to keychain",
							@"Description of key exception")];
	    
	    [attributes setObject:(id)kSecAttrKeyClassPrivate forKey:(id)kSecAttrKeyClass];
	    [attributes setObject:self.privateKey forKey:(id)kSecValueData];
	    
	    status = SecItemAdd((CFDictionaryRef)attributes, NULL);
	    
	    if (status != errSecSuccess)
		[self _raiseException:NSLocalizedString(@"Could not add private key to keychain",
							@"Description of key exception")];
	    
	    // Now look up the keys again
	    status = SecItemCopyMatching((CFDictionaryRef)parameters, 
					 (CFTypeRef *)&search_result);
	    
	    if (status != errSecSuccess)
		[self _raiseException:NSLocalizedString(@"Could not find generated key pair",
							@"Description of key generation exception")];
	    
	    [myPublicKey release];
	    [myPrivateKey release];
	}
	
	if (status == errSecSuccess)
	{
	    // Find the public and private keys and store the data
	    // we need to send our public key to another iPhone
	    for (NSDictionary * item in search_result)
	    {
		NSString * key_type = [[item objectForKey:(id)kSecAttrKeyClass] stringValue];
		if ([key_type isEqualToString:(id)kSecAttrKeyClassPrivate])
		    myPrivateKey = [[item objectForKey:(id)kSecValueData] retain];
		else 
		    myPublicKey = [[item objectForKey:(id)kSecValueData] retain];
	    }
	}
    }
    
    
    return self;    
}

#else

- (id)initWithName:(NSString*)name
{
    self = [super init];
    if (self != nil) {
	
	myPrivateKey = [[SSCrypto generateRSAPrivateKeyWithLength:kKeySize] retain];
	myPublicKey = [[SSCrypto generateRSAPublicKeyFromPrivateKey:self.privateKey] retain];

    }
    return self;
}

+ (SecKeyRef)keyFromPublicKeyData:(NSData*)data
{
    return NULL;
}

#endif

@end

@implementation KeychainKeyPair (Private)

#if ! TARGET_IPHONE_SIMULATOR

+ (void)_deleteAllKeys
{
    OSStatus status;
    NSDictionary * parameters;
    parameters = [NSDictionary dictionaryWithObjectsAndKeys:
		  (id)kSecClassKey, kSecClass,
		  nil];
    status = SecItemDelete((CFDictionaryRef)parameters);
}

+ (void)_dumpAllKeys
{
    OSStatus status;
    NSDictionary * parameters;
    parameters = [NSDictionary dictionaryWithObjectsAndKeys:
		  (id)kSecClassKey, kSecClass,
		  (id)kCFBooleanTrue, kSecReturnAttributes,
		  (id)kCFBooleanTrue,	    kSecReturnData,
		  kSecMatchLimitAll, kSecMatchLimit,
		  nil];
    
    NSArray * keys = nil;
    status = SecItemCopyMatching((CFDictionaryRef)parameters, (CFTypeRef*)&keys);
    
    NSLog(@"KEY DUMP");
    if (keys)
    {
	for (NSDictionary * item in keys)
	{
	    NSLog(@"Key: %@",item);
	}
    }
}

#else

+ (void)_dumpAllKeys
{}

#endif

- (void)_raiseException:(NSString*)message
{
    NSException * exception;
    exception = [NSException exceptionWithName:NSLocalizedString(@"Keychain Error", @"Name of keychain exception") 
					reason:message 
				      userInfo:nil];
    @throw exception;    
}


@end

