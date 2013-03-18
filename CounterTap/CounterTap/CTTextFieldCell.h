//
//  CTTextFieldCell.h
//  CounterTap
//
//  Created by Jeff Davis on 3/16/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

@class CTTextFieldCell;

@protocol CTTextFieldDelegate <NSObject>
@optional
- (void)textFieldCellDidBeginEditing:(CTTextFieldCell*)cell;
- (void)textFieldCellTextDidChange:(CTTextFieldCell*)cell;
- (void)textFieldCellDidEndEditing:(CTTextFieldCell*)cell;
- (void)textFieldDidReturn:(CTTextFieldCell*)cell;
- (void)textFieldDownWasTapped:(CTTextFieldCell*)cell;
@end

@interface CTTextFieldCell : UITableViewCell
@property(nonatomic, assign) id<CTTextFieldDelegate> delegate;

@property(nonatomic, assign) BOOL alwaysEditable;
@property(nonatomic, assign) CGFloat labelWidth;
@property(nonatomic, readonly) UITextField* textField;
@end