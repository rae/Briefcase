//
//  BookmarkListController.m
//  Briefcase
//
//  Created by Michael Taylor on 16/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "BookmarkListController.h"
#import "File.h"

static NSString * kBookmarkCell = @"Bookmark Cell";

@implementation BookmarkListController

- (id)initWithFile:(File*)file
{
    if (self = [super initWithNibName:@"BookmarkListView" bundle:nil])
    {
	myFile = [file retain];
	self.bookmarks = file.bookmarks;
	self.navigationItem.title = NSLocalizedString(@"Bookmarks","Title for view that shows a list of document bookmarks");
	self.navigationItem.hidesBackButton = YES;
	
	myDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
								     target:self 
								     action:@selector(done)];
	myEditButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
								     target:self 
								     action:@selector(doEdit)];
	myEditDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
									 target:self 
									 action:@selector(doneEdit)];		
	self.navigationItem.rightBarButtonItem = myDoneButton;		
    }
    return self;
}

 - (void)loadView 
{
    [super loadView];
    [myNavigationBar pushNavigationItem:self.navigationItem animated:NO];
    [myToolbar setItems:[NSArray arrayWithObject:myEditButton]];
}
 
- (IBAction) doEdit
{
    [myTableView setEditing:YES animated:YES];
    [myToolbar setItems:[NSArray arrayWithObject:myEditDoneButton] animated:YES];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
}

- (IBAction) doneEdit
{
    [myTableView setEditing:NO animated:YES];
    [myToolbar setItems:[NSArray arrayWithObject:myEditButton] animated:YES];
    [self.navigationItem setRightBarButtonItem:myDoneButton animated:YES];
}

- (void)done
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
 - (void)viewDidLoad {
 }
 */

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
    [myFile release];
    [myBookmarks release];
    [super dealloc];
}

#pragma mark Table View Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [myBookmarks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)index_path
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:kBookmarkCell];
    if (cell == nil) {
	cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kBookmarkCell] autorelease];
    }	  
    
    NSArray * item = [myBookmarks objectAtIndex:index_path.row];
    
    cell.text = [item objectAtIndex:0];
    
    cell.showsReorderControl = YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)index_path
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
	[myBookmarks removeObjectAtIndex:index_path.row];
	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:index_path] 
			 withRowAnimation:UITableViewRowAnimationLeft];
	myFile.bookmarks = [NSArray arrayWithArray:myBookmarks];
	[myFile save];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{    
    [myBookmarks exchangeObjectAtIndex:fromIndexPath.row withObjectAtIndex:toIndexPath.row];
    myFile.bookmarks = [NSArray arrayWithArray:myBookmarks];
    [myFile save];
}

#pragma mark Table View Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index_path
{
    id location = [[myBookmarks objectAtIndex:index_path.row] objectAtIndex:1];
    
    LongPoint position = LongPointZero;
    
    if ([location isKindOfClass:[NSString class]])
	position = LongPointFromNSString((NSString*)location);
    else
	position.y = [location longLongValue];
    
    [myDelegate setDocumentPosition:position];
    
    [self done];
}

#pragma mark Properties

@synthesize delegate = myDelegate;

- (NSArray*)bookmarks
{
    return myBookmarks;
}

- (void)setBookmarks:(NSArray*)bookmarks
{
    [myBookmarks release];
    myBookmarks = [[NSMutableArray alloc] initWithArray:bookmarks];
}

@end
