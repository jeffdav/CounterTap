//
//  CTTextFieldCell.m
//  CounterTap
//
//  Created by jorf on 3/16/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CTTextFieldCell.h"

@interface CTTextFieldCell ()
@end

@implementation CTTextFieldCell

#define kMargin 10.0
#define kOffset 1.0

@synthesize delegate = _delegate;

@synthesize alwaysEditable = _alwaysEditable;
@synthesize labelWidth = _labelWidth;
@synthesize textField = _textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        _textField = [[[UITextField alloc] init] autorelease];
        _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _textField.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:_textField];

        self.selectionStyle = UITableViewCellSelectionStyleNone;

        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:_textField];
        [center addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:_textField];
        [center addObserver:self selector:@selector(didEndEditing:) name:UITextFieldTextDidEndEditingNotification object:_textField];
    }
    return self;
}

- (void)dealloc {
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:_textField];
    [center removeObserver:self name:UITextFieldTextDidChangeNotification object:_textField];
    [center removeObserver:self name:UITextFieldTextDidEndEditingNotification object:_textField];

    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect contentBounds = self.contentView.bounds;
    
    CGRect labelFrame = self.textLabel.frame;
    if (_labelWidth > 0.0) {
        labelFrame.size.width = _labelWidth;
    } else {
        CGSize size = [self.textLabel sizeThatFits:contentBounds.size];
        labelFrame.size.width = size.width;
    }
    self.textLabel.frame = labelFrame;
    
    CGRect fieldFrame;
    fieldFrame.origin.x = labelFrame.origin.x + labelFrame.size.width + kMargin;
    fieldFrame.origin.y = kOffset;
    fieldFrame.size.width = contentBounds.size.width - fieldFrame.origin.x - kMargin;
    fieldFrame.size.height = contentBounds.size.height - kOffset;
    _textField.frame = fieldFrame;
}

- (void)setAlwaysEditable:(BOOL)alwaysEditable {
    _alwaysEditable = alwaysEditable;
    if (_alwaysEditable) {
        _textField.enabled = YES;
    }
}

- (void)setLabelWidth:(CGFloat)width {
    _labelWidth = width;
    [self setNeedsLayout];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        [_textField becomeFirstResponder];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (!_alwaysEditable) {
        _textField.enabled = editing;
    }
}

- (void)textDidChange:(NSNotification*)notification {
    if ([_delegate respondsToSelector:@selector(textFieldCellTextDidChange:)]) {
        [_delegate textFieldCellTextDidChange:self];
    }
}

- (void)didBeginEditing:(NSNotification*)notification {
    UITableView* tableView = (UITableView*)self.superview;
    [tableView selectRowAtIndexPath:[tableView indexPathForCell:self] animated:YES scrollPosition:UITableViewScrollPositionNone];

    if ([_delegate respondsToSelector:@selector(textFieldCellDidBeginEditing:)]) {
        [_delegate textFieldCellDidBeginEditing:self];
    }
}

- (void)didEndEditing:(NSNotification*)notification {
    if ([_delegate respondsToSelector:@selector(textFieldCellDidEndEditing:)]) {
        [_delegate textFieldCellDidEndEditing:self];
    }
}

@end
