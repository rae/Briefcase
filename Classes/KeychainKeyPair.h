//
//  KeychainKeyPair.h
//  Briefcase
//
//  Created by Michael Taylor on 02/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#include <Security/Security.h>

@interface KeychainKeyPair : NSObject 
{    
    NSData      * myPublicKey;
    NSData      * myPrivateKey;
    NSString    * myPublicKeyPath;
    NSString    * myPrivateKeyPath;
}

@property (readonly) NSData     * privateKey;
@property (readonly) NSData     * publicKey;
@property (readonly) NSString   * privateKeyPath;
@property (readonly) NSString   * publicKeyPath;

+ (BOOL)existsPairWithName:(NSString*)name;
+ (void)deletePairWithName:(NSString*)name;

- (id)initWithName:(NSString*)name;
- (id)initWithName:(NSString*)name keySize:(NSInteger)size;

@end
