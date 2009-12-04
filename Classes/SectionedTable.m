//
//  SectionedTable.m
//  Briefcase
//
//  Created by Michael Taylor on 09-07-25.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import "SectionedTable.h"

@interface SectionedTable (Private)

- (NSString*)sectionIDAtIndex:(NSUInteger)section_index;

@end


@implementation SectionedTable

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame style:UITableViewStyleGrouped];
    if (self != nil) 
    {
	mySectionsByID = [[NSMutableDictionary alloc] init];
	self.delegate = self;
	self.dataSource = self;
    }
    return self;
}

- (void)dealloc 
{
    [mySectionsByID release];
    [myActiveSections release];
    [super dealloc];
}

- (void)addSection:(NSObject <TableSection> *)section withID:(NSString*)section_id
{
    [mySectionsByID setObject:section forKey:section_id];
}

- (void)setActiveSectionIDs:(NSArray*)active_section_ids
{
    for (NSString * section_id in active_section_ids) 
    {
	if (![mySectionsByID objectForKey:section_id])
	    [NSException raise:@"Invalid Section" format:@"Invalid section passed to setActiveSectionIDs"];
	[myActiveSections release];
	myActiveSections = [active_section_ids retain];
    }
    [self reloadData];
}

- (void)deleteRow:(NSUInteger)row 
	inSection:(NSString*)section_id 
 withRowAnimation:(UITableViewRowAnimation)animation
{
    NSUInteger index = [myActiveSections indexOfObject:section_id];
    
    if (index != NSNotFound) 
    {
	NSIndexPath * path = [NSIndexPath indexPathForRow:row inSection:index];
	[self deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] 
		    withRowAnimation:animation];
    }
}

- (void)deselectRow:(NSUInteger)row 
	  inSection:(NSString*)section_id
	   animated:(BOOL)animated
{
    NSUInteger index = [myActiveSections indexOfObject:section_id];
    
    if (index != NSNotFound) 
    {
	NSIndexPath * path = [NSIndexPath indexPathForRow:row inSection:index];
	[self deselectRowAtIndexPath:path animated:animated];
    }
}

- (NSIndexPath*)indexPathForRow:(NSUInteger)row inSection:(NSString*)section_id
{
    NSUInteger index = [myActiveSections indexOfObject:section_id];
    return [NSIndexPath indexPathForRow:row inSection:index];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    if (myActiveSections)
	return [myActiveSections count];
    else
	return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section_index
{
    NSString * section_id = [self sectionIDAtIndex:section_index];
    NSObject <TableSection> * section = [mySectionsByID objectForKey:section_id];
    
    return [section sectionedTable:self numberOfRowsInSection:section_id];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)index_path 
{
    NSString * section_id = [self sectionIDAtIndex:index_path.section];
    NSObject <TableSection> * section = [mySectionsByID objectForKey:section_id];
    
    return [section sectionedTable:self cellInSection:section_id forRow:index_path.row];
}
    
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)index_path
{
    NSString * section_id = [self sectionIDAtIndex:index_path.section];
    NSObject <TableSection> * section = [mySectionsByID objectForKey:section_id];
    
    return [section sectionedTable:self heightInSection:section_id forRow:index_path.row];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section_index
{
    NSString * section_id = [self sectionIDAtIndex:section_index];
    NSObject <TableSection> * section = [mySectionsByID objectForKey:section_id];
    
    return [section sectionedTable:self titleForSection:section_id];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)index_path
{
    NSString * section_id = [self sectionIDAtIndex:index_path.section];
    NSObject <TableSection> * section = [mySectionsByID objectForKey:section_id];
    
    return [section sectionedTable:self canEditInSection:section_id forRow:index_path.row];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)index_path
{
    NSString * section_id = [self sectionIDAtIndex:index_path.section];
    NSObject <TableSection> * section = [mySectionsByID objectForKey:section_id];
    
    return [section sectionedTable:self section:section_id commitEditingStyle:editingStyle forRow:index_path.row];
}

#pragma mark UITableViewDelegate methods

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)index_path
{
    NSString * section_id = [self sectionIDAtIndex:index_path.section];
    NSObject <TableSection> * section = [mySectionsByID objectForKey:section_id];
    
    if ([section sectionedTable:self section:section_id canSelectRow:index_path.row])
	return index_path;
    else
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index_path 
{
    NSString * section_id = [self sectionIDAtIndex:index_path.section];
    NSObject <TableSection> * section = [mySectionsByID objectForKey:section_id];
    
    return [section sectionedTable:self section:section_id didSelectRow:index_path.row];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)index_path
{
    NSString * section_id = [self sectionIDAtIndex:index_path.section];
    NSObject <TableSection> * section = [mySectionsByID objectForKey:section_id];
    
    return [section sectionedTable:self section:section_id editingStyleForRow:index_path.row];
}

#pragma mark Private Methods

- (NSString*)sectionIDAtIndex:(NSUInteger)section_index
{
    if (!myActiveSections || section_index >= [myActiveSections count])
	[NSException raise:@"Invalid Section" format:@"Section index out of range"];

    return [myActiveSections objectAtIndex:section_index];
}

@end
