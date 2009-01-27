//
//  DownloadedFileBrowser.m
//  Briefcase
//
//  Created by Michael Taylor on 20/05/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "DownloadedFileBrowser.h"
#import "Utilities.h"
#import "UploadActionController.h"
#import "IconManager.h"
#import "File.h"
#import "FileType.h"
#import "BriefcaseCell.h"
#import "ConnectionController.h"
#import "GradientTableView.h"


#define FLOATRGBA(A,B,C) colorWithRed:((CGFloat)A/255.0) green:((CGFloat)B/255.0) blue:((CGFloat)C/255.0) alpha:1.0
#define kCellShadow			FLOATRGBA(184, 184, 184)

#define kFileCell @"File Cell"

@implementation DownloadedFileBrowser

- (id)initWithUploadController:(UploadActionController*)controller localPath:(NSString*)path
{
    if (self = [super initWithNibName:@"DownloadedFileView" bundle:nil]) 
    {
	myUploadController = [controller retain];
	
	self.navigationItem.title = NSLocalizedString(@"Briefcase Files", @"Title for screen that displays the files stored in Briefcase");
	
	// Add edit button to navigation bar 
	self.navigationItem.rightBarButtonItem = [self editButtonItem];
	
	// Register to here about connection status changes so that
	// we can change our button
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(_connectionEstablished:) 
		       name:kMainConnectionEstablished 
		     object:nil];
	[center addObserver:self 
		   selector:@selector(_connectionTerminated:) 
		       name:kMainConnectionTerminated
		     object:nil];
	
	[center addObserver:self selector:@selector(_filesChanged:) 
		       name:kFileDeleted 
		     object:nil];
	[center addObserver:self selector:@selector(_filesChanged:) 
		       name:kFileChanged 
		     object:nil];
	[center addObserver:self selector:@selector(_filesChanged:) 
		       name:kDirectoryDeleted 
		     object:nil];
	
	myLocalPath = [path retain];
	
	if ([path length] == 0)
	{
	    // We'll show the search button at the top level
	    mySearchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
									   target:self 
									   action:@selector(toggleSearch)];
	    self.navigationItem.leftBarButtonItem = mySearchButton;
	}
    }
    return self;
}

- (NSArray*) _getUpdatedFileList
{
    NSArray * result = nil;
    
    if (!mySearchBar.hidden && [mySearchBar.text length] > 0)
	result = [[File searchForFilesMatching:mySearchBar.text] retain];
    else
	// Reload the heirarchical data
	result = [[File fileListAtLocalPath:myLocalPath] retain];
    
    return result;
}

- (void)setFilterText:(NSString*)text
{
    if (![text isEqualToString:mySearchBar.text])
	mySearchBar.text = text;
    [myDirectoryEntries release];
    myDirectoryEntries = [self _getUpdatedFileList];
    [myTableView reloadData];
}

- (void)showSearchAnimated:(BOOL)animated
{
    // Show the options UI elements
    mySearchBar.hidden = NO;
    if (animated)
	[UIView beginAnimations:@"Search Field" context:nil];
    
    CGRect frame = mySearchBar.frame;
    frame.origin.y = 0;
    mySearchBar.frame = frame;
    
    CGPoint content_offset = myTableView.contentOffset;
    content_offset.y -= frame.size.height;
    myTableView.contentOffset = content_offset;
    
    if (animated)
	[UIView commitAnimations];
    
    UIEdgeInsets insets = myTableView.contentInset;
    insets.top = frame.size.height;
    myTableView.contentInset = insets;
    
    insets = myTableView.scrollIndicatorInsets;
    insets.top = frame.size.height;
    myTableView.scrollIndicatorInsets = insets;
    
    [self setFilterText:mySearchBar.text];
    
    [mySearchBar becomeFirstResponder];
}

- (void)hideSearchDone
{
    mySearchBar.hidden = YES;
}
    
- (void)hideSearchAnimated:(BOOL)animated
{            
    if (mySearchBar.hidden)
	return;
    
    [mySearchBar resignFirstResponder];
    
    if (animated)
    {
	[UIView beginAnimations:@"Search Field" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(hideSearchDone)];
    }
    
    CGRect frame = mySearchBar.frame;
    frame.origin.y = -frame.size.height;
    mySearchBar.frame = frame;
    
    CGPoint content_offset = myTableView.contentOffset;
    content_offset.y += frame.size.height;
    myTableView.contentOffset = content_offset;
    
    if (animated)
	[UIView commitAnimations];
    
    UIEdgeInsets insets = myTableView.contentInset;
    insets.top = 0.0;
    myTableView.contentInset = insets;
    
    insets = myTableView.scrollIndicatorInsets;
    insets.top = 0.0;
    myTableView.scrollIndicatorInsets = insets;
    
    [self setFilterText:@""];
        
    if (!animated)
	[self hideSearchDone];
}

- (void)toggleSearch
{
    if (mySearchBar.hidden)
	[self showSearchAnimated:YES];
    else
	[self hideSearchAnimated:YES];
}

- (void)searchBar:(UISearchBar *)search_bar textDidChange:(NSString *)search_text
{
    [self setFilterText:search_text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [mySearchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    mySearchBar.text = @"";
    [self hideSearchAnimated:YES];
}

- (void)keyboardBecameVisible:(NSNotification*)notification
{
    NSValue * value = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
    CGRect bounds;
    [value getValue:&bounds];
    value = [[notification userInfo] objectForKey:UIKeyboardCenterEndUserInfoKey];
    CGPoint keyboard_center;
    [value getValue:&keyboard_center];
    
    // Calculate the frame for the keyboard
    CGRect keyboard_frame = CGRectMake(keyboard_center.x - (bounds.size.width / 2.0), 
				       keyboard_center.y - (bounds.size.height / 2.0), 
				       bounds.size.width, bounds.size.height);
    
    // Find the top most parent view to translate into screen
    // coords (the keyboard is in screen coords)
    UIView * top_view = myTableView.superview;
    while (top_view.superview)
	top_view = top_view.superview;
    
    // Get the frame for this controller's view (a parent of the table)
    // We do this because the table view's frame moves as you scroll
    CGRect view_frame = [self.view convertRect:self.view.frame toView:top_view];
    
    // Calculate the intersection between the keyboard and the
    // table view
    CGRect intersection = CGRectIntersection(keyboard_frame, view_frame);
        
    // Adjust our inset to account for the overlap
    UIEdgeInsets insets = myTableView.contentInset;
    insets.bottom = intersection.size.height;
    myTableView.contentInset = insets;
    
    insets = myTableView.scrollIndicatorInsets;
    insets.bottom = intersection.size.height;
    myTableView.scrollIndicatorInsets = insets;
}

- (void)keyboardBecameHidden:(NSNotification*)notification
{
    UIEdgeInsets insets = myTableView.contentInset;
    insets.bottom = 0;
    myTableView.contentInset = insets; 
    
    insets = myTableView.scrollIndicatorInsets;
    insets.bottom = 0;
    myTableView.scrollIndicatorInsets = insets; 
}

- (void)viewDidLoad 
{
    myTableView.rowHeight = kBriefcaseCellHeight;
    myTableView.separatorColor = [UIColor kCellShadow];
    mySearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    mySearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    [self hideSearchAnimated:NO];
    myTableView.contentOffset = CGPointZero;
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (mySearchBar.hidden)
    {
	[myDirectoryEntries release];
	myDirectoryEntries = [[File fileListAtLocalPath:myLocalPath] retain];
	[myTableView reloadData];
    }
    else
	[self setFilterText:mySearchBar.text];
    
    // Register to find out when the keyboard appears
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self 
	       selector:@selector(keyboardBecameVisible:) 
		   name:UIKeyboardDidShowNotification 
		 object:nil];
    [center addObserver:self 
	       selector:@selector(keyboardBecameHidden:) 
		   name:UIKeyboardDidHideNotification 
		 object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [myDirectoryEntries release];
    myDirectoryEntries = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Register to find out when the keyboard disappears
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [center removeObserver:self name:UIWindowDidBecomeHiddenNotification object:nil];
}


- (void)dealloc 
{
    [mySearchButton release];
    [myDirectoryEntries release];
    [myUploadController release];
    
    [super dealloc];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [myTableView setEditing:editing animated:YES];
}

- (void)refreshDownloadList
{
    if (myDirectoryEntries)
    {
	[myDirectoryEntries release];
	myDirectoryEntries = [[File fileListAtLocalPath:myLocalPath] retain];
	[myTableView reloadData];
    }
}

- (void)_connectionEstablished:(NSNotification*)notification
{
    [BriefcaseCell setBriefcaseCellAccessory:kUploadIcon];
    [self refreshDownloadList];
}

- (void)_connectionTerminated:(NSNotification*)notification
{
    [BriefcaseCell setBriefcaseCellAccessory:kInfoIcon];
    [self refreshDownloadList];
}

- (void)_filesChanged:(NSNotification*)notification
{
    if (!myDirectoryEntries) return;

    NSArray * new_entries = [self _getUpdatedFileList];

    if ([new_entries isEqualToArray:myDirectoryEntries])
    {
	// Some element in the list has been modified
	[myTableView reloadData];
	return;
    }
    
    NSSet * old = [NSSet setWithArray:myDirectoryEntries];
    NSSet * new = [NSSet setWithArray:new_entries];
    
    // Update our array
    NSArray * old_entries = myDirectoryEntries;
    myDirectoryEntries = new_entries;
    [myDirectoryEntries retain];
    
    if (!myTableView.editing)
    {
	// Table is not in edit mode, so we cannot animate
	[old_entries release];
	[myTableView reloadData];
	[myTableView setNeedsLayout];
	return;
    }
    
    NSMutableSet * removed_files = [NSMutableSet setWithSet:old];
    [removed_files minusSet:new];
    
    if ([removed_files count] > 0)
    {
	NSMutableArray * array = [NSMutableArray array];;
	for (id object in removed_files)
	{
	    NSUInteger index = [old_entries indexOfObject:object];
	    if (index != NSNotFound)
		[array addObject:[NSIndexPath indexPathForRow:index inSection:0]];
	}
	
	if ([array count] > 0)
	    [myTableView deleteRowsAtIndexPaths:array 
			       withRowAnimation:UITableViewRowAnimationLeft];
    }
    else
    {
	// Just update the table
	[myTableView reloadData];
	[myTableView setNeedsDisplay];
    }
    
    
    [old_entries release];
}

#pragma mark UITableViewDelegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    NSInteger result = 0;
    
    if (myDirectoryEntries)
    {
	result = [myDirectoryEntries count];
    }
    
    return result;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index_path 
{
    if (!mySearchBar.hidden)
	// Make sure that the keyboard goes away
	[mySearchBar resignFirstResponder];
    
    id item = [myDirectoryEntries objectAtIndex:index_path.row];
    
    if ([item isKindOfClass:[NSString class]])
    {
	// Directory
	UINavigationController * parent_nav_controller = (UINavigationController*)self.parentViewController;
	DownloadedFileBrowser * sub_directory;
	sub_directory = [[DownloadedFileBrowser alloc] initWithUploadController:myUploadController 
								      localPath:[myLocalPath stringByAppendingPathComponent:item]];
	[parent_nav_controller pushViewController:sub_directory animated:YES];
    }
    else
    {
	// File
	File * file = (File*)item;
	FileType * file_type = [FileType findBestMatch:file];
	[file_type viewFile:file];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
	 cellForRowAtIndexPath:(NSIndexPath *)index_path 
{
    BriefcaseCell * cell = (BriefcaseCell*)[tableView dequeueReusableCellWithIdentifier:kBriefcaseCellId];
    if (cell == nil) {
	cell = [[[BriefcaseCell alloc] initWithFrame:CGRectZero] autorelease];
    }	    
    
    id item = [myDirectoryEntries objectAtIndex:index_path.row];
    
    if ([item isKindOfClass:[NSString class]])
    {
	cell.fileName = item;
	cell.fileType = [Utilities descriptionFromUTI:@"public.folder"];
	cell.icon = [IconManager iconForFolderSmall:NO];
	cell.file = nil;
    }
    else
    {
	File * file = (File*)item;
	cell.fileName = [file.fileName stringByDeletingPathExtension];
	
	[file hydrate];
	
	NSString * description = nil;
	NSString * extension = [file.fileName pathExtension];
	NSString * uti = [Utilities utiFromFileExtension:[extension lowercaseString]];
	if (uti)
	    description = [Utilities descriptionFromUTI:uti];
	if (!description)
	    description = extension;
	
	cell.fileType = description;
	cell.file = file;
	
	cell.icon = file.iconImage;
	if (!cell.icon)
	    cell.icon = [IconManager iconForFile:file.fileName smallIcon:NO];
    }
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView 
	   editingStyleForRowAtIndexPath:(NSIndexPath *)index_path
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)index_path
{
    
    id item = [myDirectoryEntries objectAtIndex:index_path.row];
    
    if ([item isKindOfClass:[NSString class]])
    {
	// Directory
	[File deleteDirectoryAtLocalPath:[myLocalPath stringByAppendingPathComponent:item]];
    }
    else
    {
	// File
	[(File*)item delete];
    }
}

@end
