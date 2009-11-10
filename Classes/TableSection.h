//
//  TableSection.h
//  Briefcase
//
//  Created by Michael Taylor on 09-07-25.
//  Copyright 2009 Hey Mac Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SectionedTable;

@protocol TableSection

- (NSString*)sectionedTable:(SectionedTable*)table titleForSection:(NSString*)section_id;
- (CGFloat)sectionedTable:(SectionedTable*)table heightInSection:(NSString*)section_id forRow:(NSUInteger)row;
- (UITableViewCell*)sectionedTable:(SectionedTable*)table cellInSection:(NSString*)section_id forRow:(NSUInteger)row;
- (NSInteger)sectionedTable:(SectionedTable*)table numberOfRowsInSection:(NSString*)section_id;
- (BOOL)sectionedTable:(SectionedTable*)table canEditInSection:(NSString*)section_id forRow:(NSUInteger)row;
- (void)sectionedTable:(SectionedTable*)table section:(NSString*)section_id commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRow:(NSUInteger)row;
- (BOOL)sectionedTable:(SectionedTable*)table section:(NSString*)section_id canSelectRow:(NSUInteger)row;
- (void)sectionedTable:(SectionedTable*)table section:(NSString*)section_id didSelectRow:(NSUInteger)row;
- (UITableViewCellEditingStyle)sectionedTable:(SectionedTable*)table section:(NSString*)section_id editingStyleForRow:(NSUInteger)row;

@end
