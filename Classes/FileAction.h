//
//  FileAction.h
//  Briefcase
//
//  Created by Michael Taylor on 03/09/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class File;
@class BCConnection;

@interface FileAction : NSObject 
{
    NSString *	    myTitle;
    id		    myTarget;
    SEL		    myOperationAction;
    BOOL	    myRequiresMac;
}

@property (nonatomic,retain) NSString * title;
@property (nonatomic,retain) id		target;
@property (nonatomic,assign) SEL	operationAction;
@property (nonatomic,assign) BOOL	requiresMac;

@property (nonatomic,readonly) UITableViewCellAccessoryType accessoryType;

+ (FileAction*)fileActionWithTitle:(NSString*)title 
			    target:(id)target 
			  selector:(SEL)selector 
		       requiresMac:(BOOL)mac;

- (NSString*)identifierForFile:(File*)file;
- (NSArray*)queueOperationsForFile:(File*)file connection:(BCConnection*)connection;

+ (NSArray*)operationsForUploadOfFile:(File*)file toPath:(NSString*)remote_path;
+ (NSArray*)operationsForUploadOfFile:(File*)file withRemoteShellCommand:(NSString*)command;

@end
