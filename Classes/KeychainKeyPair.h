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
    NSData * myPrivateKey;
    NSData * myPublicKey;
}

@property (readonly) NSData * privateKey;
@property (readonly) NSData * publicKey;

- (id)initWithName:(NSString*)name;

@end
