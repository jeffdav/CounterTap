//
//  CTCounterTableViewController.m
//  CounterTap
//
//  Created by jorf on 3/16/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CTCounterTableViewController.h"

#import "CTCounter.h"
#import "CTTextFieldCell.h"

@interface CTCounterTableViewController () {
  @private
    NSMutableArray* _items;

    UIBarButtonItem* _addItem;
    UIBarButtonItem* _doneItem;
}
- (void)loadItems;
- (void)persistItems;
- (void)syncData;

- (void)styleCounterCell:(UITableViewCell*)cell atIndex:(NSInteger)index;
- (void)styleOptionsCell:(UITableViewCell*)cell atIndex:(NSInteger)index;
- (void)handleOption:(NSInteger)option;

- (void)addItemWasTapped:(id)sender;
- (void)doneItemWasTapped:(id)sender;
- (void)willEnterBackground:(id)sender;
@end

@interface CTCounterTableViewController () <CTTextFieldDelegate>
- (void)textFieldCellDidEndEditing:(CTTextFieldCell *)cell;
@end

typedef void (^ConfirmBlock)(NSInteger option);

@interface CTCounterTableViewController () <UIActionSheetDelegate> {
    NSInteger _optionPendingConfirm;
    ConfirmBlock _blockPendingConfirm;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)confirmOption:(NSInteger)option withBlock:(ConfirmBlock)block;
@end

enum {
    CTCounterView_CounterSection,
    CTCounterView_OptionsSection,

    CTCounterView_SectionCount
};

enum {
    CTCounterView_OptionExport,
    CTCounterView_OptionResetAll,
    CTCounterView_OptionRemoveAll,

    CTCounterView_OptionsCount
};

NSString* const CTDefaults_ItemsKey = @"CTDefaults_ItemsKey";

@implementation CTCounterTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self loadItems];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (_blockPendingConfirm) Block_release(_blockPendingConfirm);
    _blockPendingConfirm = nil;

    [_items release];
    [_addItem release];
    [_doneItem release];

    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _addItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleBordered target:self action:@selector(addItemWasTapped:)];
    _doneItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneItemWasTapped:)];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = _addItem;
    self.navigationItem.title = @"CounterTap!";

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self persistItems];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    self.navigationItem.rightBarButtonItem.enabled = !editing;
    
    [self syncData];
}

#pragma mark - Internal

- (void)loadItems {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSData* data = [defaults objectForKey:CTDefaults_ItemsKey];
    if (data != nil) {
        NSArray* array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (array != nil) {
            _items = [[NSMutableArray alloc] initWithArray:array];
        }
    }

    if (_items == nil) {
        _items = [[NSMutableArray alloc] init];
        CTCounter* counter = [[CTCounter alloc] init];
        counter.title = @"Example counter";
        counter.count = 2;
        [_items addObject:counter];
    }
}

- (void)persistItems {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:_items];
    [defaults setObject:data forKey:CTDefaults_ItemsKey];
    [defaults synchronize];
}

- (void)syncData {
    
}

- (void)willEnterBackground:(id)sender {
    [self persistItems];
}

- (void)styleCounterCell:(UITableViewCell *)cell atIndex:(NSInteger)index {
    CTCounter* counter = [_items objectAtIndex:index];
    CTTextFieldCell* textfieldCell = (id)cell;
    textfieldCell.textField.text = counter.title;
    textfieldCell.detailTextLabel.text = [NSString stringWithFormat:@"%d", counter.count];
}

- (void)styleOptionsCell:(UITableViewCell *)cell atIndex:(NSInteger)index {
    switch (index) {
        case CTCounterView_OptionExport:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"Export";
            break;
        case CTCounterView_OptionResetAll:
            cell.textLabel.text = @"Reset All";
            break;
        case CTCounterView_OptionRemoveAll:
            cell.textLabel.text = @"Remove All";
            break;
    }
}

- (void)addItemWasTapped:(id)sender {
    [self.tableView setEditing:YES animated:YES];

    if ([_items count] == 0) {
        UITableViewHeaderFooterView* footer = [self.tableView footerViewForSection:CTCounterView_CounterSection];
        footer.textLabel.text = nil;
    }

    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:_items.count inSection:CTCounterView_CounterSection];
    CTCounter* counter = [[[CTCounter alloc] init] autorelease];
    [_items addObject:counter];
    [self.tableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];

    CTTextFieldCell* textfieldCell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
    [textfieldCell.textField becomeFirstResponder];

    self.navigationItem.rightBarButtonItem = _doneItem;
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)doneItemWasTapped:(id)sender {
    [self.tableView setEditing:NO animated:YES];

    self.navigationItem.rightBarButtonItem = _addItem;
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)handleOption:(NSInteger)option {
    switch (option) {
        case CTCounterView_OptionResetAll:
            [self confirmOption:option withBlock:^(NSInteger option) {
                [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    CTCounter* counter = obj;
                    counter.count = 0;
                }];
                [self.tableView reloadData];
                [self persistItems];
            }];

        case CTCounterView_OptionRemoveAll:
            [self confirmOption:option withBlock:^(NSInteger option) {
                [_items removeAllObjects];
                [self.tableView reloadData];
                [self persistItems];
            }];
            break;

        default:
            break;
    }
}

- (void)confirmOption:(NSInteger)option withBlock:(ConfirmBlock)block {
    _optionPendingConfirm = option;
    _blockPendingConfirm = Block_copy(block);

    NSString* title;
    NSString* destructive;
    switch (option) {
        case CTCounterView_OptionResetAll:
            title = @"Reset all counters to 0?\nThis cannot be undone.";
            destructive = @"Reset All";
            break;
        case CTCounterView_OptionRemoveAll:
            title = @"Delete all timers?\nThis cannot be undone.";
            destructive = @"Delete All";
            break;
        default:
            title = @"Confirm?";
            destructive = @"Yes";
            break;
    }

    UIActionSheet* sheet = [[[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:destructive otherButtonTitles:nil] autorelease];
    [sheet showFromRect:self.tableView.frame inView:self.view animated:YES];
}

#pragma mark - CTTextFieldCellDelegate

- (void)textFieldCellDidEndEditing:(CTTextFieldCell *)cell {
    NSIndexPath* path = [self.tableView indexPathForCell:cell];

    // This can happen if the item was deleted while being edited.
    if (path.row >= [_items count]) return;

    CTCounter* counter = [_items objectAtIndex:path.row];
    counter.title = cell.textField.text;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        _blockPendingConfirm(_optionPendingConfirm);
        Block_release(_blockPendingConfirm);
        _blockPendingConfirm = nil;
        _optionPendingConfirm = 0;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return CTCounterView_SectionCount;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case CTCounterView_CounterSection: return @"Counters";
        case CTCounterView_OptionsSection: return @"Options";
        default: return nil;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case CTCounterView_CounterSection:
            if ([_items count] == 0) {
                return @"Tap the Add button to create a counter...";
            }
            return nil;
        default: return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case CTCounterView_CounterSection: return [_items count];
        case CTCounterView_OptionsSection: return CTCounterView_OptionsCount;
        default: return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *counterCellId = @"CTCounterCellId";
    static NSString *optionCellId = @"CTCounterCellOption";
    UITableViewCell *cell = nil;

    switch (indexPath.section) {
        case CTCounterView_CounterSection: cell = [tableView dequeueReusableCellWithIdentifier:counterCellId]; break;
        case CTCounterView_OptionsSection: cell = [tableView dequeueReusableCellWithIdentifier:optionCellId]; break;
    }

    if (cell == nil) {
        switch (indexPath.section) {
            case CTCounterView_CounterSection: {
                CTTextFieldCell* textfieldCell = [[[CTTextFieldCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:counterCellId] autorelease];
                textfieldCell.alwaysEditable = NO;
                textfieldCell.delegate = self;
                cell = textfieldCell;
                break;
            }

            case CTCounterView_OptionsSection:
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:optionCellId] autorelease];
                break;
        }
    }

    switch (indexPath.section) {
        case CTCounterView_CounterSection: [self styleCounterCell:cell atIndex:indexPath.row]; break;
        case CTCounterView_OptionsSection: [self styleOptionsCell:cell atIndex:indexPath.row]; break;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case CTCounterView_CounterSection: return YES;
        default: return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_items removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];

        if ([_items count] == 0) {
            [self doneItemWasTapped:self];
            [tableView reloadData];
        }
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        NSLog(@"commitEditingStyle: wants to insert an item.");
    }   
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [_items exchangeObjectAtIndex:fromIndexPath.row withObjectAtIndex:toIndexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case CTCounterView_CounterSection: return YES;
        default: return NO;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case CTCounterView_CounterSection: {
            CTCounter* counter = [_items objectAtIndex:indexPath.row];
            counter.count++;
            [tableView reloadData];
            break;
        }

        case CTCounterView_OptionsSection:
            [self handleOption:indexPath.row];
            break;

        default:
            break;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        NSInteger row = 0;
        if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
            row = [tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
        }
        return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];
    }
    return proposedDestinationIndexPath;
}

@end
