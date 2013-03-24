//
//  CTGraphViewController.m
//  CounterTap
//
//  Created by jorf on 3/23/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CTGraphViewController.h"

#import "CorePlotHeaders/CorePlot-CocoaTouch.h"

@interface CTGraphViewController () <CPTPlotDataSource> {
    NSArray* _counters;
    CPTXYGraph* _graph;
}
@end

@implementation CTGraphViewController

- (id)init {
    return [self initWithCounters:[NSArray array]];
}

- (id)initWithCounters:(NSArray*)counters {
    if (self = [super init]) {
        _counters = [counters retain];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadView {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CPTGraphHostingView* view = [[[CPTGraphHostingView alloc] initWithFrame:bounds] autorelease];
    self.view = view;

    CPTTheme* theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];

    _graph = [[[CPTXYGraph alloc] initWithFrame:bounds] autorelease];
    [_graph applyTheme:theme];

    view.hostedGraph = _graph;
}

#pragma mark - CPTPlotDataSource

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return [_counters count];
}

@end
