//
//  SectionedTable.h
//  Briefcase
//
//  Created by Michael Taylor on 09-07-25.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableSection.h"

@interface SectionedTable : UITableView <UITableViewDelegate,UITableViewDataSource> 
{
    NSMutableDictionary * mySectionsByID;
    NSArray		* myActiveSections;
}

- (void)addSection:(NSObject <TableSection> *)section withID:(NSString*)id;
- (void)setActiveSectionIDs:(NSArray*)active_section_ids;

- (void)deleteRow:(NSUInteger)row 
	inSection:(NSString*)section_id 
 withRowAnimation:(UITableViewRowAnimation)animation;

- (void)deselectRow:(NSUInteger)row 
	  inSection:(NSString*)section_id
	   animated:(BOOL)animated;

- (NSIndexPath*)indexPathForRow:(NSUInteger)row inSection:(NSString*)section_id;

@end
