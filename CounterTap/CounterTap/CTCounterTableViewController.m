//
//  CTCounterTableViewController.m
//  CounterTap
//
//  Created by jorf on 3/16/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CTCounterTableViewController.h"

#import <MessageUI/MessageUI.h>

#import "JSONKit.h"

#import "CTCounter.h"
#import "CTGraphViewController.h"
#import "CTTextFieldCell.h"

@interface CTCounterTableViewController () {
  @private
    NSMutableArray* _items;

    UIBarButtonItem* _addItem;
    UIBarButtonItem* _doneItem;
}
- (void)loadItems;
- (void)persistItems;

- (void)styleCounterCell:(UITableViewCell*)cell atIndex:(NSInteger)index;
- (void)styleOptionsCell:(UITableViewCell*)cell atIndex:(NSInteger)index;
- (void)styleActionCell:(UITableViewCell *)cell atIndex:(NSInteger)index;
- (void)handleOption:(NSInteger)option;
- (void)handleAction:(NSInteger)option;

- (void)addItemWasTapped:(id)sender;
- (void)doneItemWasTapped:(id)sender;
- (void)willEnterBackground:(id)sender;
@end

@interface CTCounterTableViewController () <CTTextFieldDelegate>
- (void)textFieldCellDidEndEditing:(CTTextFieldCell *)cell;
- (void)textFieldDidReturn:(CTTextFieldCell *)cell;
- (void)textFieldDownWasTapped:(CTTextFieldCell *)cell;
@end

typedef void (^ConfirmBlock)(NSInteger option);

@interface CTCounterTableViewController () <UIActionSheetDelegate> {
    NSInteger _optionPendingConfirm;
    ConfirmBlock _blockPendingConfirm;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)confirmOption:(NSInteger)option withBlock:(ConfirmBlock)block;

- (void)pickExportType;
- (void)doExport:(NSInteger)exportType;

- (void)pickSortType;
- (void)doSort:(NSInteger)sortType;
@end

@interface CTCounterTableViewController () <MFMailComposeViewControllerDelegate>
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
@end

enum {
    CTCounterView_CounterSection,
    CTCounterView_ActionsSection,
    CTCounterView_OptionsSection,

    CTCounterView_SectionCount
};

enum {
    CTCounterView_OptionSort,
    CTCounterView_OptionResetAll,
    CTCounterView_OptionRemoveAll,

    CTCounterView_OptionsCount
};

enum {
    CTCounterView_ActionExport,
    CTCounterView_ActionGraph,

    CTCounterView_ActionCount
};

enum {
    CTCounterView_TitleAscSort,
    CTCounterView_TitleDscSort,
    CTCounterView_CountAscSort,
    CTCounterView_CountDscSort,

    CTCounterView_SortCount
};

enum {
    CTCounterView_JSONExportType,
    CTCounterView_CSVExportType,

    CTCounterView_ExportTypeCount
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

    if (_blockPendingConfirm) {
        Block_release(_blockPendingConfirm);
        _blockPendingConfirm = nil;
    }

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
    self.navigationItem.leftBarButtonItem.enabled = [_items count] > 0;
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
    }
}

- (void)persistItems {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:_items];
    [defaults setObject:data forKey:CTDefaults_ItemsKey];
    [defaults synchronize];
}

- (void)willEnterBackground:(id)sender {
    [self persistItems];
}

#pragma mark Cell Styling

- (void)styleCounterCell:(UITableViewCell *)cell atIndex:(NSInteger)index {
    CTCounter* counter = [_items objectAtIndex:index];
    CTTextFieldCell* textfieldCell = (id)cell;
    textfieldCell.textField.text = counter.title;
    textfieldCell.detailTextLabel.text = [NSString stringWithFormat:@"%d", counter.count];
}

- (void)styleOptionsCell:(UITableViewCell *)cell atIndex:(NSInteger)index {
    switch (index) {
        case CTCounterView_OptionSort:
            cell.textLabel.text = @"Sort...";
            break;
        case CTCounterView_OptionResetAll:
            cell.textLabel.text = @"Reset All";
            break;
        case CTCounterView_OptionRemoveAll:
            cell.textLabel.text = @"Remove All";
            break;
    }
}

- (void)styleActionCell:(UITableViewCell *)cell atIndex:(NSInteger)index {
    switch (index) {
        case CTCounterView_ActionExport:
            cell.textLabel.text = @"Export...";
            break;
        case CTCounterView_ActionGraph:
            cell.textLabel.text = @"Graph";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
    }
}

#pragma mark BarButtonItems

- (void)addItemWasTapped:(id)sender {
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:_items.count inSection:CTCounterView_CounterSection];
    CTCounter* counter = [[[CTCounter alloc] init] autorelease];
    [_items addObject:counter];
    [self.tableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];

    [self.tableView reloadData];

    CTTextFieldCell* textfieldCell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
    [textfieldCell.textField becomeFirstResponder];

    self.navigationItem.rightBarButtonItem = _doneItem;
    self.navigationItem.leftBarButtonItem.enabled = NO;

    [self setEditing:YES animated:YES];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)doneItemWasTapped:(id)sender {
    self.navigationItem.rightBarButtonItem = _addItem;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [self setEditing:NO animated:NO];
}

#pragma mark Options

- (void)handleOption:(NSInteger)option {
    switch (option) {
        case CTCounterView_OptionResetAll:
            [self confirmOption:option withBlock:^(NSInteger option) {
                [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    CTCounter* counter = obj;
                    [counter clearTaps];
                }];
                [self.tableView reloadData];
                [self persistItems];
            }];
            break;

        case CTCounterView_OptionRemoveAll:
            [self confirmOption:option withBlock:^(NSInteger option) {
                [_items removeAllObjects];
                [self.tableView reloadData];
                [self persistItems];
                self.navigationItem.leftBarButtonItem.enabled = NO;
            }];
            break;

        case CTCounterView_OptionSort:
            [self pickSortType];
            break;

        default:
            break;
    }
}

- (void)handleAction:(NSInteger)option {
    switch (option) {
        case CTCounterView_ActionGraph: {
            CTGraphViewController* graphController = [[[CTGraphViewController alloc] initWithCounters:_items] autorelease];
            [self.navigationController pushViewController:graphController animated:YES];
            break;
        }

        case CTCounterView_ActionExport:
            if ([MFMailComposeViewController canSendMail]) {
                [self pickExportType];
            } else {
                [[[[UIAlertView alloc] initWithTitle:@"No e-mail configured." message:@"Export is done via e-mail. Please configure an e-mail account and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
            }
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
            title = @"Delete all counters?\nThis cannot be undone.";
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

#pragma mark Exporting

- (void)pickExportType {
    _optionPendingConfirm = CTCounterView_ActionExport;
    UIActionSheet* sheet = [[[UIActionSheet alloc] initWithTitle:@"Export format?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"JSON", @"CSV", nil] autorelease];
    [sheet showFromRect:self.tableView.frame inView:self.view animated:YES];
}

- (void)doExport:(NSInteger)exportType {
    NSData* exportData = nil;
    NSString* mimeType = nil;
    NSString* fileName = nil;
    switch (exportType) {
        case CTCounterView_JSONExportType: {
            __block NSMutableArray* array = [NSMutableArray arrayWithCapacity:[_items count]];
            [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [array addObject:[obj asDictionary]];
            }];
            exportData = [array JSONData];
            mimeType = @"application/json";
            fileName = @"export.json";
            break;
        }

        case CTCounterView_CSVExportType: {
            __block NSMutableString* string = [[[NSMutableString alloc] initWithString:[CTCounter headerForCSV]] autorelease];
            [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [string appendString:[obj asRowForCSV]];
            }];
            exportData = [string dataUsingEncoding:NSUTF8StringEncoding];
            mimeType = @"text/csv; header=present";
            fileName = @"export.csv";
            break;
        }
    }

    MFMailComposeViewController* controller = [[[MFMailComposeViewController alloc] init] autorelease];
    controller.mailComposeDelegate = self;
    [controller setSubject:@"CounterTap Data Export"];
    [controller setMessageBody:@"Your data is attached.  Thanks for using CounterTap." isHTML:NO];
    [controller addAttachmentData:exportData mimeType:mimeType fileName:fileName];
    [self presentViewController:controller animated:YES completion:^{}];
}

#pragma mark Sorting

- (void)pickSortType {
    _optionPendingConfirm = CTCounterView_OptionSort;
    UIActionSheet* sheet = [[[UIActionSheet alloc] initWithTitle:@"Sort how?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
                                               otherButtonTitles:@"Title, Ascending", @"Title, Descending", @"Count, Ascending", @"Count, Descending", nil] autorelease];
    [sheet showFromRect:self.tableView.frame inView:self.view animated:YES];
}

- (void)doSort:(NSInteger)sortType {
    switch (sortType) {
        case CTCounterView_TitleAscSort:
            [_items sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [[obj1 title] compare:[obj2 title]];
            }];
            break;

        case CTCounterView_TitleDscSort:
            [_items sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSComparisonResult result = [[obj1 title] compare:[obj2 title]];
                switch (result) {
                    case NSOrderedAscending: return NSOrderedDescending;
                    case NSOrderedDescending: return NSOrderedAscending;
                    default: return result;
                }
            }];
            break;

        case CTCounterView_CountAscSort:
            [_items sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSInteger left = [obj1 count];
                NSInteger right = [obj2 count];
                if (left > right) return NSOrderedDescending;
                if (left < right) return NSOrderedAscending;
                return NSOrderedSame;
            }];
            break;

        case CTCounterView_CountDscSort:
            [_items sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSInteger left = [obj1 count];
                NSInteger right = [obj2 count];
                if (left > right) return NSOrderedAscending;
                if (left < right) return NSOrderedDescending;
                return NSOrderedSame;
            }];
            break;

        default:
            break;
    }

    [self persistItems];
    [self.tableView reloadData];
}

#pragma mark - CTTextFieldCellDelegate

- (void)textFieldCellDidEndEditing:(CTTextFieldCell *)cell {
    NSIndexPath* path = [self.tableView indexPathForCell:cell];

    // This can happen if the item was deleted while being edited.
    if (path.row >= [_items count]) return;

    CTCounter* counter = [_items objectAtIndex:path.row];
    counter.title = cell.textField.text;
}

- (void)textFieldDidReturn:(CTTextFieldCell *)cell {
    //[self doneItemWasTapped:self];
}

- (void)textFieldDownWasTapped:(CTTextFieldCell *)cell {
    NSIndexPath* path = [self.tableView indexPathForCell:cell];

    if (path.row >= [_items count]) return;

    CTCounter* counter = [_items objectAtIndex:path.row];
    [counter removeLastTap];
    [self.tableView reloadData];
    [self persistItems];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        _blockPendingConfirm(_optionPendingConfirm);
        Block_release(_blockPendingConfirm);
        _blockPendingConfirm = nil;
        _optionPendingConfirm = 0;
    } else if (_optionPendingConfirm == CTCounterView_ActionExport && buttonIndex != actionSheet.cancelButtonIndex) {
        [self doExport:buttonIndex - actionSheet.firstOtherButtonIndex];
    } else if (_optionPendingConfirm == CTCounterView_OptionSort && buttonIndex != actionSheet.cancelButtonIndex) {
        [self doSort:buttonIndex - actionSheet.firstOtherButtonIndex];
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
        case CTCounterView_ActionsSection: return @"Actions";
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
        case CTCounterView_ActionsSection: return CTCounterView_ActionCount;
        default: return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *counterCellId = @"CTCounterCellId";
    static NSString *optionCellId = @"CTCounterCellOption";
    static NSString *actionCellId = @"CTCounterCellAction";
    UITableViewCell *cell = nil;

    switch (indexPath.section) {
        case CTCounterView_CounterSection: cell = [tableView dequeueReusableCellWithIdentifier:counterCellId]; break;
        case CTCounterView_OptionsSection: cell = [tableView dequeueReusableCellWithIdentifier:optionCellId]; break;
        case CTCounterView_ActionsSection: cell = [tableView dequeueReusableCellWithIdentifier:actionCellId]; break;
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
            case CTCounterView_ActionsSection:
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:optionCellId] autorelease];
                break;
        }
    }

    switch (indexPath.section) {
        case CTCounterView_CounterSection: [self styleCounterCell:cell atIndex:indexPath.row]; break;
        case CTCounterView_OptionsSection: [self styleOptionsCell:cell atIndex:indexPath.row]; break;
        case CTCounterView_ActionsSection: [self styleActionCell:cell atIndex:indexPath.row]; break;
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
            [counter addTap];
            [tableView reloadData];
            break;
        }

        case CTCounterView_OptionsSection:
            [self handleOption:indexPath.row];
            break;

        case CTCounterView_ActionsSection:
            [self handleAction:indexPath.row];
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
