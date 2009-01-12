//
//  SystemInfoController.m
//  Briefcase
//
//  Created by Michael Taylor on 05/06/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "SystemInfoController.h"
#import "ConnectionController.h"
#import "SSHCommandOperation.h"
#import "NetworkOperationQueue.h"
#import "InfoCell.h"
#import "Utilities.h"
#import "SystemInformation.h"
#import "ConnectionController.h"

#define kBasicInfoCell @"Basic Info Cell"
#define kSystemInfoLabelWidth 95

@implementation SystemInfoController

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self 
		   selector:@selector(systemInfoChanged:) 
		       name:kSystemInfoChanged 
		     object:nil];
	[center addObserver:self
		   selector:@selector(systemInfoChanged:)
		       name:kMainConnectionTerminated
		     object:nil];
	
	myTableView = nil;
	myIsConnected = NO;
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}

- (void)systemInfoChanged:(NSNotification*)notification
{
    [myTableView reloadData];
}

-(void)loadView
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    myTableView = [UITableView alloc];
    [myTableView initWithFrame:frame style:UITableViewStyleGrouped];
     
    myTableView.delegate = self;
    myTableView.dataSource = self; 
    self.view = myTableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    ConnectionController * controller = [ConnectionController sharedController];
    
    SystemInformation * info_manager = controller.currentSystemInformation;

    if ([info_manager itemCount])
    {
	return [info_manager itemCount];
    }
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index_path 
{
}

- (UITableViewCell *)tableView:(UITableView *)table_view cellForRowAtIndexPath:(NSIndexPath *)index_path 
{
    UITableViewCell * result;
    
    ConnectionController * controller = [ConnectionController sharedController];
    
    SystemInformation * info_manager = controller.currentSystemInformation;
    
    if ([info_manager itemCount])
    {
	InfoCell * cell = (InfoCell*)[table_view dequeueReusableCellWithIdentifier:kInfoCellId];
	if (cell == nil) {
	    cell = [[[InfoCell alloc] initWithFrame:CGRectZero reuseIdentifier:kInfoCellId] autorelease];
	}
	
	cell.label = [info_manager descriptionForItemAtIndex:index_path.row];
	cell.description = [info_manager valueForItemAtIndex:index_path.row];
	cell.labelWidth = kSystemInfoLabelWidth;
	
	result = cell;  
    }
    else
    {
	
	UITableViewCell * cell = [table_view dequeueReusableCellWithIdentifier:kBasicInfoCell];
	if (cell == nil) {
	    cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kBasicInfoCell] autorelease];
	}
	if (!controller.currentConnection)
	    cell.text = NSLocalizedString(@"Not Connected", @"Message in information screen when we are not connected");
	else
	    cell.text = NSLocalizedString(@"No Information Available", @"Message in information screen when we do not have any information to display");
	result = cell;
    }
    
    return result;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"System Information", @"Title for system information table");
}


@end
