//
//  KeychainItem.h
//  Briefcase
//
//  Created by Michael Taylor on 22/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KeychainItem : NSObject {
    NSDictionary *	myAttributes;
    NSMutableArray *	myDirtyAttributes;
}

@property (nonatomic,readonly) NSString * host;
@property (nonatomic,readonly) NSInteger  port;
@property (nonatomic,readonly) NSString * protocol;

@property (nonatomic,retain)   NSString * username;
@property (nonatomic,retain)   NSString * password;

+ (KeychainItem*)findOrCreateItemForHost:(NSString*)host_name
				  onPort:(NSInteger)service_port 
				protocol:(NSString*)protocol
				username:(NSString*)username;

- (id)initWithDictionary:(NSDictionary*)data;

- (void)save;


+ (void)cleanKeychain;

+ (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionary_to_convert;
+ (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionary_to_convert;

- (void)dump;

@end
