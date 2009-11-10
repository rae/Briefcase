//
//  KeychainItem.m
//  Briefcase
//
//  Created by Michael Taylor on 22/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "KeychainItem.h"

#import "BCConnectionManager.h"

#import <Security/Security.h>

#if TARGET_IPHONE_SIMULATOR
#define kSecAttrServer	 @"kSecAttrServer"
#define kSecAttrPort	 @"kSecAttrPort"
#define kSecAttrProtocol @"kSecAttrProtocol"
#define kSecAttrAccount	 @"kSecAttrAccount"
#define kSecValueData	 @"kSecValueData"
#define kSecAttrComment  @"kSecAttrComment"
#define kSecAttrProtocolSSH NULL
#endif

@implementation KeychainItem

+ (KeychainItem*)findOrCreateItemForHost:(NSString*)host_name
				  onPort:(NSInteger)service_port 
				protocol:(NSString*)protocol
				username:(NSString*)username
{
    NSNumber * port_number = [NSNumber numberWithInt:service_port];
    
    // Convert protocol into the strings used by Keychain Services
    CFTypeRef protocol_type = NULL;
    if ([protocol isEqualToString:kSSHProtocol])
	protocol_type = kSecAttrProtocolSSH;
    else
	NSLog(@"Invalid protocol %@",protocol);
    
#if TARGET_IPHONE_SIMULATOR
    
    NSDictionary * new_attributes;
    new_attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		      host_name,	    kSecAttrServer,
		      port_number,	    kSecAttrPort,
		      protocol_type,	    kSecAttrProtocol,
		      nil];
    
    return [[[KeychainItem alloc] initWithDictionary:new_attributes] autorelease];
    
#else
    
    NSDictionary * search_attributes;
    
    if (username && [username length] > 0)
	search_attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			     (id)kSecClassInternetPassword, kSecClass,
			     host_name,		    kSecAttrServer,
			     port_number,	    kSecAttrPort,
			     protocol_type,	    kSecAttrProtocol,
			     username,		    kSecAttrAccount,
			     kCFBooleanTrue,	    kSecReturnAttributes,
			     nil];
    else
	search_attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			     (id)kSecClassInternetPassword, kSecClass,
			     host_name,		    kSecAttrServer,
			     port_number,	    kSecAttrPort,
			     protocol_type,	    kSecAttrProtocol,
			     kCFBooleanTrue,	    kSecReturnAttributes,
			     nil];
	
    NSDictionary * search_result = nil;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)search_attributes, 
					  (CFTypeRef *)&search_result);
    
    if (noErr == status) {
	NSMutableDictionary * attributes = [KeychainItem secItemFormatToDictionary:search_result];
	return [[[KeychainItem alloc] initWithDictionary:attributes] autorelease];
    }
    
    // We didn't find a keychain item, so make one
    NSDictionary * new_attributes;
    if (username && [username length] > 0)
	new_attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			  (id)kSecClassInternetPassword, kSecClass,
			  host_name,		    kSecAttrServer,
			  port_number,		    kSecAttrPort,
			  username,		    kSecAttrAccount,
			  protocol_type,	    kSecAttrProtocol,
			  nil];
    else
	new_attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			  (id)kSecClassInternetPassword, kSecClass,
			  host_name,		    kSecAttrServer,
			  port_number,		    kSecAttrPort,
			  protocol_type,	    kSecAttrProtocol,
			  nil];
    
    status = SecItemAdd((CFDictionaryRef)new_attributes, NULL);
    NSAssert(status==noErr,@"Error adding new keychain item!");
    
    return [[[KeychainItem alloc] initWithDictionary:new_attributes] autorelease];
#endif
    
    
}

- (id)initWithDictionary:(NSDictionary*)data
{
    if (self = [super init])
    {
	myAttributes = [[NSMutableDictionary alloc] initWithDictionary:data];
	myDirtyAttributes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [myAttributes release];
    [myDirtyAttributes release];
    [super dealloc];
}

-(void)save
{
#if ! TARGET_IPHONE_SIMULATOR
    NSDictionary * search_attributes;
    NSDictionary * attributes = NULL;
    NSMutableDictionary * update_item = NULL;
    OSStatus status;
    
    // Only save if we need to
    if ([myDirtyAttributes count] == 0) return;
    
//    NSLog(@"kSecClass %@",[myAttributes objectForKey:(id)kSecClass]);
//    NSLog(@"kSecAttrServer %@",[myAttributes objectForKey:(id)kSecAttrServer]);
//    NSLog(@"kSecAttrPort %@",[myAttributes objectForKey:(id)kSecAttrPort]);
//    NSLog(@"kSecAttrProtocol %@",[myAttributes objectForKey:(id)kSecAttrProtocol]);
   
    
    search_attributes = [NSDictionary dictionaryWithObjectsAndKeys:
 			 (id)kSecClassInternetPassword,			   kSecClass,
 			 [myAttributes objectForKey:(id)kSecAttrServer],   kSecAttrServer,
			 [myAttributes objectForKey:(id)kSecAttrPort],     kSecAttrPort,
			 [myAttributes objectForKey:(id)kSecAttrProtocol], kSecAttrProtocol,
			 kCFBooleanTrue,				   kSecReturnAttributes,
			 nil];
    
//    NSLog(@"My Attributes %@",myAttributes);
//    NSLog(@"Search Attributes %@",search_attributes);
    
    // Look up the item's current attributes
    if (SecItemCopyMatching((CFDictionaryRef)search_attributes, (CFTypeRef *)&attributes) == noErr)
    {
//	NSLog(@"Search Attributes: %@",search_attributes);
	
	update_item = [NSMutableDictionary dictionaryWithDictionary:attributes];
	[update_item setObject:(id)kSecClassInternetPassword forKey:(id)kSecClass];
	
	NSLog(@"Returned Attributes: %@",update_item);
	
	NSMutableDictionary * update_dict;
	update_dict = [NSMutableDictionary dictionaryWithCapacity:[myDirtyAttributes count]];
	
	for (id item in myDirtyAttributes)
	    [update_dict setObject:[myAttributes objectForKey:item] forKey:item];
	[myDirtyAttributes removeAllObjects];
	
	NSMutableDictionary * temp_check = [KeychainItem dictionaryToSecItemFormat:update_dict];
        [temp_check removeObjectForKey:(id)kSecClass];
	
//	NSLog(@"Save Format: %@",update_dict);
	
	status = SecItemUpdate((CFDictionaryRef)update_item, 
			       (CFDictionaryRef)temp_check);	
	if (status != noErr)
	{
	    UIAlertView * alert;
	    
	    NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Could not save password (error %d)", @"Error message displayed when Briefcase cannot save a password"),
				  status];
	    
	    alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Password Save Error",@"Title for error message that occurs when Briefcase cannot save a password") 
					       message:message
					      delegate:nil 
				     cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label")
				     otherButtonTitles:nil];
	    [alert show];
	    [alert release];
	}
	
    }
#endif
}

+ (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionary_to_convert
{
    
#if ! TARGET_IPHONE_SIMULATOR
    NSMutableDictionary * return_dictionary;
    return_dictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary_to_convert];
    
    [return_dictionary setObject:(id)kSecClassInternetPassword forKey:(id)kSecClass];
    
    // Convert the NSString to NSData to fit the API paradigm.
    NSString * password_string = [dictionary_to_convert objectForKey:(id)kSecValueData];
    if (password_string)
    {
	NSData * data = [password_string dataUsingEncoding:NSUTF8StringEncoding];
	[return_dictionary setObject:data forKey:(id)kSecValueData];
    }
    
    return return_dictionary;
#else
    return [NSMutableDictionary dictionaryWithDictionary:dictionary_to_convert];
#endif
}

+ (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionary_to_convert
{
#if ! TARGET_IPHONE_SIMULATOR
    NSMutableDictionary * return_dictionary;
    return_dictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary_to_convert];
    
    [return_dictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [return_dictionary setObject:(id)kSecClassInternetPassword forKey:(id)kSecClass];
    
    NSData * password_data = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)return_dictionary, (CFTypeRef *)&password_data) == noErr)
    {
        [return_dictionary removeObjectForKey:(id)kSecReturnData];
        
        NSString * password = [[NSString alloc] initWithBytes:[password_data bytes] 
						       length:[password_data length] 
						     encoding:NSUTF8StringEncoding];
	[password autorelease];
        [return_dictionary setObject:password forKey:(id)kSecValueData];
    }
    
    [password_data release];
    return return_dictionary;
#else
    return [NSMutableDictionary dictionaryWithDictionary:dictionary_to_convert];
#endif
}

+ (void)cleanKeychain
{
#if ! TARGET_IPHONE_SIMULATOR
    NSDictionary * search_attributes;
    search_attributes = [NSDictionary dictionaryWithObjectsAndKeys:
 			 (id)kSecClassInternetPassword,			   kSecClass,
			 nil];
    OSStatus status = SecItemDelete((CFDictionaryRef)search_attributes);
    
    NSAssert(noErr==status,@"Error deleting keychain items!");
#endif
}

- (void)dump
{
    NSLog(@"Keychain Properties: %@",myAttributes);
}

#pragma mark Properties

@dynamic host;
@dynamic port;
@dynamic protocol;
@dynamic username;
@dynamic password;

-(NSString*)host
{
    return [myAttributes objectForKey:(id)kSecAttrServer];
}

-(void)setHost:(NSString*)host
{
    NSString * current_value = [myAttributes objectForKey:(id)kSecAttrServer];
    if (!current_value || ![host isEqualToString:current_value])
    {
	[myAttributes setValue:host forKey:(id)kSecAttrServer];
	[myDirtyAttributes addObject:(id)kSecAttrServer];
    }
}

-(NSInteger)port
{
    NSInteger result = 0;
    NSNumber * number = [myAttributes objectForKey:(id)kSecAttrPort];
    if (number)
	result = [number intValue];
    return result;
}

-(void)setPort:(NSInteger)port
{
    NSNumber * current_value = [myAttributes objectForKey:(id)kSecAttrPort];
    if (!current_value || [current_value intValue] != port)
    {
	[myAttributes setValue:[NSNumber numberWithInt:port] forKey:(id)kSecAttrPort];
	[myDirtyAttributes addObject:(id)kSecAttrPort];
    }
}
 
-(NSString*)protocol
{
    NSString * result = nil;
    
    CFTypeRef protocol_type = [myAttributes objectForKey:(id)kSecAttrProtocol];
    if (protocol_type == kSecAttrProtocolSSH)
	result = kSSHProtocol;
    else
	NSLog(@"Invalid protocol");
    
    
    return result;
}

-(void)setProtocol:(NSString*)protocol
{
    CFTypeRef protocol_type = NULL;
    if ([protocol isEqualToString:kSSHProtocol])
	protocol_type = kSecAttrProtocolSSH;
    else
	NSLog(@"Invalid protocol %@",protocol);
    
    
    NSString * current_value = self.protocol;
    if (!current_value || ![protocol isEqualToString:current_value])
    {
	[myAttributes setValue:(id)protocol_type forKey:(id)kSecAttrProtocol];
	[myDirtyAttributes addObject:(id)kSecAttrProtocol];
    }
}

-(NSString*)username
{
    NSString * result = [myAttributes objectForKey:(id)kSecAttrAccount];
    if (!result)
	result = @"";
    return result;
}

-(void)setUsername:(NSString*)username
{
    NSString * current_value = [myAttributes objectForKey:(id)kSecAttrAccount];
    if (!current_value || ![username isEqualToString:current_value])
    {
	[myAttributes setValue:username forKey:(id)kSecAttrAccount];
	[myDirtyAttributes addObject:(id)kSecAttrAccount];
    }
}

-(NSString*)password
{
    NSString * result = [myAttributes objectForKey:(id)kSecValueData];
    if (!result)
	result = @"";
    return result;
}

-(void)setPassword:(NSString*)password
{
    NSString * current_value = [myAttributes objectForKey:(id)kSecValueData];
    if (!current_value || ![password isEqualToString:current_value])
    {	
	[myAttributes setValue:password forKey:(id)kSecValueData];
	[myDirtyAttributes addObject:(id)kSecValueData];
    }
}

-(NSString*)comment
{
    return [myAttributes objectForKey:(id)kSecAttrComment];
}

-(void)setComment:(NSString*)comment
{
    NSString * current_value = [myAttributes objectForKey:(id)kSecValueData];
    if (!current_value || ![comment isEqualToString:current_value])
    {
	[myAttributes setValue:comment forKey:(id)kSecAttrComment];
	[myDirtyAttributes addObject:(id)kSecAttrComment];
    }
}

@end
