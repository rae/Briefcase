//
//  ConnectionBrowserController.m
//  Briefcase
//
//  Created by Michael Taylor on 02/11/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "ConnectionBrowserController.h"
#import "ConnectionController.h"
#import "GradientCell.h"
#import "IconManager.h"
#import "EditRemoteHostController.h"
#import "ConnectionManager.h"

NSString * kConnectionBrowserCell = @"kConnectionBrowserCell";

#define kInternetBrowserCell @"Internet Browser Cell"

#define kHostListKey		@"host_list"

#define kHostNicknameKey	@"Host Nickname"
#define kHostAddressKey		@"Host Address"
#define kHostPortKey		@"Host Port"
#define kHostUsernameKey	@"Host Username"

#define kSectionDividerTopMargin     5.0
#define kSectionDividerRightMargin  10.0

@implementation ConnectionBrowserController

- (id)init {
    if (self = [super init]) 
    {
        // Custom initialization
    }
    return self;
}

- (void)loadServerList
{
    [myHostList release];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * hosts = [defaults arrayForKey:kHostListKey];
    
    // Make our host list mutable
    if (hosts) 
    {
	myHostList = [[NSMutableArray alloc] initWithCapacity:[hosts count]];
	
	// Loop over the dictionaries in the host list and make them mutable
	for (NSDictionary * item in hosts)
	{
	    [myHostList addObject:[NSMutableDictionary dictionaryWithDictionary:item]];
	}
    }
    else
	myHostList = [[NSMutableArray alloc] init];
}

- (void)awakeFromNib
{
    myTableView.delegate = self;
    myTableView.dataSource = self;
    
    // Set up network browser
    mySSHBrowser = [[NSNetServiceBrowser alloc] init];
    [mySSHBrowser setDelegate:self];
    [mySSHBrowser searchForServicesOfType:@"_ssh._tcp." inDomain:@"local."];
    
    myBriefcaseBrowser = [[NSNetServiceBrowser alloc] init];
    [myBriefcaseBrowser setDelegate:self];
    [myBriefcaseBrowser searchForServicesOfType:@"_briefcase._tcp." inDomain:@"local."];
    
    myServices = [[NSMutableArray alloc] init];
    [self loadServerList];
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self 
	       selector:@selector(networkAvailablityChanged:)
		   name:kNetworkReachibilityChanged 
		 object:nil];
}

- (void)dealloc 
{   
    // Remove ourselves as table view delegate and data source 
    myTableView.delegate = nil;
    myTableView.dataSource = nil;
    [mySSHBrowser setDelegate:nil];
    [mySSHBrowser release];
    [myBriefcaseBrowser setDelegate:nil];
    [myBriefcaseBrowser release];
    [myServices release];
    
    [super dealloc];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated 
{
    [myTableView setEditing:editing animated:YES];
    
    // Figure out where the remote path placeholder goes
    NSIndexPath * index_path = [NSIndexPath indexPathForRow:[myHostList count] inSection:1];
    
    if (editing)
	[myTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:index_path] 
			   withRowAnimation:UITableViewRowAnimationFade];
    else
	[myTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:index_path] 
			   withRowAnimation:UITableViewRowAnimationFade];
}

- (void)updateServerListPref
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:myHostList forKey:kHostListKey];
    [defaults synchronize];
}

- (void)addItemDone:(EditRemoteHostController*)controller
{     
    if (!controller.cancelled)
    {
	NSMutableDictionary * item;
	item = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		controller.nickname, kHostNicknameKey,
		controller.serverAddress, kHostAddressKey,
		[NSNumber numberWithUnsignedInt:controller.port], kHostPortKey,
		controller.username, kHostUsernameKey,
		nil];
	[myHostList addObject:item];
	
	[myTableView reloadData];
	
	[self updateServerListPref];
    }
    
    [controller release];
}

- (void)editItemDone:(EditRemoteHostController*)controller
{     
    if (!controller.cancelled)
    {
	NSMutableDictionary * item;
	item = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		controller.nickname, kHostNicknameKey,
		controller.serverAddress, kHostAddressKey,
		[NSNumber numberWithUnsignedInt:controller.port], kHostPortKey,
		controller.username, kHostUsernameKey,
		nil];
	[myHostList replaceObjectAtIndex:[myHostList indexOfObject:myEditItem] 
			      withObject:item];
	
	[myTableView reloadData];
	
	[myEditItem release];
	myEditItem = nil;
	
	[self updateServerListPref];
    }
    
    [controller release];
}

- (void)networkAvailablityChanged:(NSNotification*)notification
{
    [myTableView reloadData];
}

- (void)newBookmark
{
    
    NSDictionary * item = nil;
    
    UINavigationController * nav_controller;
    nav_controller = (UINavigationController*)myConnectionController.parentViewController;
    
    EditRemoteHostController * controller;
    controller = [[EditRemoteHostController alloc] initWithNavigationController:nav_controller];
    controller.port = 22;
    controller.nickname = @"";
    controller.username = @"";
    controller.serverAddress = @"";
    controller.target = self;
    controller.action = @selector(addItemDone:);
    [nav_controller pushViewController:controller animated:YES];
    myEditItem = [item retain];
}

#pragma mark UITableView Data Source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
#if BRIEFCASE_LITE  
    return 1;
#else
    return 2;
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    if (section == 0)
	// Bonjour section
	return MAX(1, [myServices count]);
    else if (myConnectionController.editing)
	// Bookmark section (add one because of new item field)
	return [myHostList count] + 1;
    else
	return [myHostList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
	 cellForRowAtIndexPath:(NSIndexPath *)index_path 
{
    // Create a cell if necessary
    UITableViewCell * cell = [myTableView dequeueReusableCellWithIdentifier:kConnectionBrowserCell];
    if (!cell)
    {
	cell = [[[GradientCell alloc] initWithFrame:CGRectZero 
				    reuseIdentifier:kConnectionBrowserCell] autorelease];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.image = nil;

    if (index_path.section == 0)
    {
	if ([myServices count] == 0) 
	{
	    ConnectionManager * manager = [ConnectionManager sharedManager];
	    if (manager.wifiAvailable)
		// If there are no services, show one row that tells the user that.
		cell.text = NSLocalizedString(@"No Local Machines", @"Message when there are no local machines");
	    else
		// If there's no WiFi for Bonjour, tell the user that
		cell.text = NSLocalizedString(@"No WiFi Network",@"Message to the user telling them that no WiFi network is available");
	    return cell;
	}
	else
	{
	    // Bonjour service
	    NSNetService * service = [myServices objectAtIndex:index_path.row];
	    cell.text = [service name];
	    
	    if ([[service type] isEqualToString:@"_ssh._tcp."])
		cell.image = [IconManager iconForBonjour];
	    else
		cell.image = [IconManager iconForiPhone];
	    
	    cell.showsReorderControl = NO;
	}
    }
    else
    {
	if (index_path.row < [myHostList count])
	{
	    // Bookmark
	    NSDictionary * item = [myHostList objectAtIndex:index_path.row];
	    
	    NSString * name = [item objectForKey:kHostNicknameKey];
	    if (!name || [name length] == 0)
		name = [item objectForKey:kHostAddressKey];
	    
	    NSAssert(name!=nil,@"Null name!");
	    
	    cell.text = name;
	    cell.showsReorderControl = YES;
	    cell.image = [IconManager iconForGenericServer];	
	}
	else
	{
	    cell.text = NSLocalizedString(@"Add Remote Host", @"Title for screen where you add a new remote host to bookmark list");
	    cell.showsReorderControl = NO;
	    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	    cell.hidesAccessoryWhenEditing = NO;
	}
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 1 && indexPath.row < [myHostList count]);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{    
    if (toIndexPath.section != 1 || toIndexPath.row >= [myHostList count])
    {
	// We cannot move that there
	[myTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
	return;
    }
    
    [myHostList exchangeObjectAtIndex:fromIndexPath.row withObjectAtIndex:toIndexPath.row];
    [self updateServerListPref];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check if they are selecting the "No Network" item
    if (indexPath.section == 0 && [myServices count] <= indexPath.row)
	return nil;
    
    if (!myTableView.editing || indexPath.section == 1)
	return indexPath;
    else
	return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)index_path
{
    NSAssert(index_path.section == 1, @"Invalid section");
    
    if (index_path.row < [myHostList count])
    {
	NSAssert(editingStyle == UITableViewCellEditingStyleDelete,@"Mismatched editing style");
	[myHostList removeObjectAtIndex:index_path.row];
	[self updateServerListPref];
	[myTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:index_path] withRowAnimation:YES];
    }
    else
    {
	NSAssert(editingStyle == UITableViewCellEditingStyleInsert,@"Mismatched editing style");
	[self tableView:myTableView didSelectRowAtIndexPath:index_path];
	return;
    }
}

#pragma mark UITableViewDelegate methods

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
	return UITableViewCellEditingStyleNone;
    else if (indexPath.section == 1 && indexPath.row < [myHostList count])
	return UITableViewCellEditingStyleDelete;
    else 
	return UITableViewCellEditingStyleInsert;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index_path
{
    // When a row is selected, resolve the service and open the web site.
    
    if (myConnectionController)
    {
	if (index_path.section == 0)
	{
	    // Bonjour service
	    NSNetService * service = [myServices objectAtIndex:index_path.row];
	    [myConnectionController connectTo:service];
	    [myTableView deselectRowAtIndexPath:index_path animated:YES];
	}
	else
	{
	    NSDictionary * item = nil;
	    NSString * host, * username, * display_name;
	    NSNumber * port;
	    SEL action;
	    
	    if (index_path.row < [myHostList count])
	    {
		item = [myHostList objectAtIndex:index_path.row];
		
		host = [item objectForKey:kHostAddressKey];
		port = [item objectForKey:kHostPortKey];
		username = [item objectForKey:kHostUsernameKey];
		display_name = [item objectForKey:kHostNicknameKey];
		
		action = @selector(editItemDone:);
	    }
	    else
	    {
		host = @"";
		port = [NSNumber numberWithInt:22];
		username = @"";
		display_name = @"";
		
		action = @selector(addItemDone:);
	    }
	    
	    if (myTableView.editing)
	    {
		UINavigationController * nav_controller;
		nav_controller = (UINavigationController*)myConnectionController.parentViewController;
		
		EditRemoteHostController * controller;
		controller = [[EditRemoteHostController alloc] initWithNavigationController:nav_controller];
		controller.port = [port intValue];
		controller.nickname = display_name;
		controller.username = username;
		controller.serverAddress = host;
		controller.target = self;
		controller.action = action;
		[nav_controller pushViewController:controller animated:YES];
		myEditItem = [item retain];
	    }
	    else
	    {
		[myConnectionController connectToHost:host atPort:[port unsignedIntValue] 
					 withUsername:username displayName:display_name];
	    }	    
	}
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 32.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame;

    // Create background view
    UIView * view = [[UIView alloc] init];
    view.autoresizesSubviews = YES;
    view.frame = CGRectMake(0.0, 0.0, tableView.frame.size.width, 35.0);
    
    // Add background
    UIImageView * background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"section_background.png"]];
    background.frame = view.bounds;
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [view addSubview:background];
    
    // Add label
    UILabel * label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    
    
    if (section == 0)
	label.text = NSLocalizedString(@"Local", @"Title for browsing local machines in connect tab");
    else
	label.text = NSLocalizedString(@"Remote", @"Title for browsing remote machines in connect tab");
	
    label.opaque = NO;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:18];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor darkGrayColor];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [label sizeToFit];
    frame = label.frame;
    frame.size.height = 35.0;
    frame.origin.x = 10.0;
    label.frame = frame;
    [view addSubview:label];
    
    if (section == 1)
    {
	// Add plus button
	UIButton * add_button = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
	[add_button setImage:[UIImage imageNamed:@"section_plus.png"] 
		    forState:UIControlStateNormal];
	[add_button setImage:[UIImage imageNamed:@"section_plus_pressed.png"] 
		    forState:UIControlStateHighlighted];
	[add_button sizeToFit];
	CGRect frame = add_button.frame;
	frame.origin.x = tableView.frame.size.width - frame.size.width - kSectionDividerRightMargin;
	frame.origin.y = kSectionDividerTopMargin;
	add_button.frame = frame;
	add_button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[add_button addTarget:self 
		       action:@selector(newBookmark) 
	     forControlEvents:UIControlEventTouchUpInside];
	[view addSubview:add_button];
    }
    
    
    return view;
}

#pragma mark Net sercices callbacks

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser 
	   didFindService:(NSNetService *)netService 
	       moreComing:(BOOL)moreServicesComing
{
    if ([[netService name] isEqualToString:[[UIDevice currentDevice] name]])
	return;
    
    [myServices addObject:netService];
    [myTableView reloadData];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser 
	 didRemoveService:(NSNetService *)netService 
	       moreComing:(BOOL)moreServicesComing
{
    [myServices removeObject:netService];
    [myTableView reloadData];
}

@end
