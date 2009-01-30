//
//  HeyMac.h
//  Briefcase
//
//  Created by Michael Taylor on 30/01/09.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#   define HMLog(...) NSLog(__VA_ARGS__)
#   define HMAssert(A,B) NSAssert(A,B)
#else
#   define HMLog(...) /* */
#   define HMAssert(A,B)
#endif
