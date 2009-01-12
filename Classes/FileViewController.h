//
//  FileViewController.h
//  Briefcase
//
//  Created by Michael Taylor on 02/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class File;

@interface FileViewController : NSObject {

}

+ (FileViewController*)sharedController;

- (void)viewFile:(File*)path;

@end
