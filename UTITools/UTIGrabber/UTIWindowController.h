//
//  UTIViewController.h
//  UTIGrabber
//
//  Created by Michael Taylor on 10/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UTIWindowController : NSWindowController {
    IBOutlet NSTextView * myTextView;
    NSDictionary * myDict;
}

- (IBAction)doLoadUTIList:(id)sender;
- (IBAction)doSaveMapping:(id)sender;

@end
