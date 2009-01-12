
#import <UIKit/UIKit.h>

// cell identifier for this custom cell
#define kUICell_ID @"UICell_ID"

#define kCellLeftOffset			8.0
#define kCellTopOffset			12.0
#define kPageControlWidth		160.0

@interface UICell : UITableViewCell
{
	UILabel		*nameLabel;
	UIView		*view;
}

@property (nonatomic, retain) UIView *view;
@property (nonatomic, retain) UILabel *nameLabel;

- (void)setView:(UIView *)inView;

@end
