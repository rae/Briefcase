
#import <UIKit/UIKit.h>

// cell identifier for this custom cell
#define kTextFieldCellID @"TextFieldCellID"
#define kCellLeftOffset			8.0
#define kCellTopOffset			12.0
#define kTextFieldHeight  30
#define kTextFieldWidth  150

@interface TextFieldCell : UITableViewCell <UITextFieldDelegate>
{
    UITextField * myView;
}

@property (nonatomic, retain) UITextField * view;

@end
