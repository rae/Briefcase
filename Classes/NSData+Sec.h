//
//  NSData+Crypto.h
//  Briefcase
//
//  Created by Michael Taylor on 02/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Security/Security.h>

@interface NSData (Sec) 

- (NSData*)encryptWithPublicKey:(NSData*)key;
- (NSData*)decryptWithPrivateKey:(NSData*)key;
- (NSData*)encryptWithSymmetricKey:(NSData*)key;
- (NSData*)decryptWithSymmetricKey:(NSData*)key;

@end
