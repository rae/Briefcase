//
//  NSData+Crypto.m
//  Briefcase
//
//  Created by Michael Taylor on 02/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "NSData+Sec.h"
#import "SSCrypto.h"

//#define NO_ENCRYPTION

@implementation NSData (Sec) 

#ifndef NO_ENCRYPTION

- (NSData*)encryptWithPublicKey:(NSData*)key
{
    NSData * result = nil;
    
    SSCrypto * crypto = [[SSCrypto alloc] initWithPublicKey:key];    
    [crypto setClearTextWithData:self];
    result = [crypto encrypt];
    [crypto release];
    
    return result;
}

- (NSData*)decryptWithPrivateKey:(NSData*)key
{
    NSData * result = nil;
    
    SSCrypto * crypto = [[SSCrypto alloc] initWithPrivateKey:key];    
    [crypto setCipherText:self];
    result = [crypto decrypt];
    [crypto release];
    
    return result;    
}

- (NSData*)encryptWithSymmetricKey:(NSData*)key
{
    NSData * result = nil;
    
    SSCrypto * crypto = [[SSCrypto alloc] initWithSymmetricKey:key];    
    [crypto setClearTextWithData:self];
    result = [crypto encrypt:@"aes256"];
    [crypto release];
    
    return result;
    
}

- (NSData*)decryptWithSymmetricKey:(NSData*)key
{
    NSData * result = nil;
    
    SSCrypto * crypto = [[SSCrypto alloc] initWithSymmetricKey:key];    
    [crypto setCipherText:self];
    result = [crypto decrypt:@"aes256"];
    [crypto release];
    
    return result;    
}

#else

- (NSData*)encryptWithPublicKey:(NSData*)key
{
    return self;
}

- (NSData*)decryptWithPrivateKey:(NSData*)key
{
    return self;   
}

- (NSData*)encryptWithSymmetricKey:(NSData*)key
{
    return self;
}

- (NSData*)decryptWithSymmetricKey:(NSData*)key
{
    return self;   
}

#endif

@end
