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
    NSMutableDictionary* _items;

    UIBarButtonItem* _addItem;
    UIBarButtonItem* _doneItem;
}
- (void)loadItems;
- (void)persistItems;

- (void)styleCounterCell:(UITableViewCell*)cell atIndex:(NSInteger)index;
- (void)styleOptionsCell:(UITableViewCell*)cell atIndex:(NSInteger)index;

- (void)addItemWasTapped:(id)sender;
- (void)doneItemWasTapped:(id)sender;
- (void)willEnterBackground:(id)sender;
@end

@interface CTCounterTableViewController () <CTTextFieldDelegate>
- (void)textFieldCellDidEndEditing:(CTTextFieldCell *)cell;
@end

enum {
    CTCounterView_CounterSection,
    CTCounterView_OptionsSection,

    CTCounterView_SectionCount
};

enum {
    CTCounterView_OptionExport,

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

    [_items release];
    [_addItem release];
    [_doneItem release];

    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    _addItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleBordered target:self action:@selector(addItemWasTapped:)];
    self.navigationItem.rightBarButtonItem = _addItem;

    _doneItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneItemWasTapped:)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self persistItems];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Internal

- (void)loadItems {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSData* data = [defaults objectForKey:CTDefaults_ItemsKey];
    if (data != nil) {
        NSDictionary* dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (dictionary != nil) {
            _items = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
        }
    }

    if (_items == nil) {
        _items = [[NSMutableDictionary alloc] init];
        CTCounter* counter = [[CTCounter alloc] init];
        counter.title = @"Example counter";
        counter.count = 2;
        [_items setObject:counter forKey:[NSNumber numberWithInt:0]];
    }
}

- (void)persistItems {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:_items];
    [defaults setObject:data forKey:CTDefaults_ItemsKey];
}

- (void)willEnterBackground:(id)sender {
    [self persistItems];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    self.navigationItem.rightBarButtonItem.enabled = !editing;
}

- (void)styleCounterCell:(UITableViewCell *)cell atIndex:(NSInteger)index {
    CTCounter* counter = [_items objectForKey:[NSNumber numberWithInt:index]];
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
    }
}

- (void)addItemWasTapped:(id)sender {
    [self.tableView setEditing:YES animated:YES];

    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:_items.count inSection:CTCounterView_CounterSection];
    CTCounter* counter = [[[CTCounter alloc] init] autorelease];
    [_items setObject:counter forKey:[NSNumber numberWithInt:_items.count]];
    [self.tableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];

    self.navigationItem.rightBarButtonItem = _doneItem;
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)doneItemWasTapped:(id)sender {
    [self.tableView setEditing:NO animated:YES];

    self.navigationItem.rightBarButtonItem = _addItem;
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

#pragma mark - CTTextFieldCellDelegate

- (void)textFieldCellDidEndEditing:(CTTextFieldCell *)cell {
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return CTCounterView_SectionCount;
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
        [_items removeObjectForKey:[NSNumber numberWithInt:indexPath.row]];
        [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        NSLog(@"commitEditingStyle wants to insert an item.");
    }   
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
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
            CTCounter* counter = [_items objectForKey:[NSNumber numberWithInt:indexPath.row]];
            counter.count++;
            [tableView reloadData];
            break;
        }

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
