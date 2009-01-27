//
//  ActivityViewController.m
//  Briefcase
//
//  Created by Michael Taylor on 07/08/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ActivityViewController.h"
#import "ActivityViewCell.h"
#import "NetworkOperation.h"
#import "GradientTableView.h"

static UINavigationController * theNavigationController = nil;

@implementation ActivityViewController

+ (UINavigationController*)navigationController
{
    if (!theNavigationController)
    {
	ActivityViewController * controller = [[ActivityViewController alloc] init];
	theNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    }
    return theNavigationController;
}

- (id)init 
{
    if (self = [super initWithStyle:UITableViewStylePlain]) 
    {
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	
	[center addObserver:self 
		   selector:@selector(networkOperationQueued:) 
		       name:kNetworkOperationQueued
		     object:nil];
	
	[center addObserver:self 
		   selector:@selector(networkOperationBegan:) 
		       name:kNetworkOperationBegan
		     object:nil];
	
	[center addObserver:self 
		   selector:@selector(networkOperationEnded:) 
		       name:kNetworkOperationEnd 
		     object:nil];
	
	[center addObserver:self 
		   selector:@selector(networkOperationEnded:) 
		       name:kNetworkOperationCancelled 
		     object:nil];
	
	myOperationList = [[NSMutableArray alloc] init];
	
	self.tableView = [[GradientTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	
	self.tableView.rowHeight = kActivityCellHeight;
	self.navigationItem.title = NSLocalizedString(@"Activity", @"Title for screen that shows the currect background activities in progress (downloads or uploads)");
	myAllowUpdates = NO;
    }
    return self;
}

- (void)networkOperationQueued:(NSNotification*)notification
{
    [myOperationList addObject:[notification object]];
    
    // Stop the application from sleeping while there is 
    // network activity
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    theNavigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [myOperationList count]];
    
    if (myAllowUpdates)
	[self.tableView reloadData];
}

- (void)networkOperationBegan:(NSNotification*)notification
{
    if (myAllowUpdates)
	[self.tableView reloadData];
}

- (void)networkOperationEnded:(NSNotification*)notification
{
    NSUInteger index = [myOperationList indexOfObjectIdenticalTo:[notification object]];
	
    if (index != NSNotFound)
	[myOperationList removeObjectAtIndex:index];
    
    NSUInteger count = [myOperationList count];
    if (count > 0)
	theNavigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", count];
    else
    {
	theNavigationController.tabBarItem.badgeValue = nil;
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
    
    if (myAllowUpdates)
	[self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [myOperationList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)index_path 
{
    
    static NSString * cell_id = @"Activity View Cell";
    
    ActivityViewCell * cell = (ActivityViewCell*)[tableView dequeueReusableCellWithIdentifier:cell_id];
    if (cell == nil) {
	cell = [[[ActivityViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cell_id] autorelease];
    }
    // Configure the cell
    NetworkOperation * op = [myOperationList objectAtIndex:index_path.row];
    cell.operation = op;
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)index_path
{
    return nil;
}

- (void)dealloc 
{
    [myOperationList release];
    [super dealloc];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    myAllowUpdates = YES;
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated 
{
    myAllowUpdates = NO;
}

- (void)viewDidDisappear:(BOOL)animated 
{
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

@end

