//
//  CTGraphViewController.m
//  CounterTap
//
//  Created by jorf on 3/23/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CTGraphViewController.h"

#import "CorePlotHeaders/CorePlot-CocoaTouch.h"

#import "CTCounterGraphDataSource.h"

@interface CTGraphViewController () {
    CPTXYGraph* _graph;
    CTCounterGraphDataSource* _dataSource;
}
@end

static NSArray* _colors = nil;
static NSArray* _symbols = nil;

@implementation CTGraphViewController

+ (void)initialize {
    // TODO(jeff): There's got to be a better way to generate colors.
    _colors = [@[ [CPTColor redColor], [CPTColor greenColor], [CPTColor blueColor],
                  [CPTColor yellowColor], [CPTColor cyanColor], [CPTColor magentaColor],
                  [CPTColor orangeColor], [CPTColor purpleColor], [CPTColor brownColor] ] retain];

    // TODO(jeff): Ditto symbols.
    _symbols = [@[ [CPTPlotSymbol ellipsePlotSymbol], [CPTPlotSymbol rectanglePlotSymbol],
                   [CPTPlotSymbol diamondPlotSymbol], [CPTPlotSymbol trianglePlotSymbol],
                   [CPTPlotSymbol pentagonPlotSymbol], [CPTPlotSymbol hexagonPlotSymbol],
                   [CPTPlotSymbol starPlotSymbol], [CPTPlotSymbol crossPlotSymbol],
                   [CPTPlotSymbol plusPlotSymbol] ] retain];
}

- (id)init {
    return [self initWithCounters:[NSArray array]];
}

- (id)initWithCounters:(NSArray*)counters {
    if (self = [super init]) {
        _dataSource = [[CTCounterGraphDataSource alloc] initWithCounters:counters];
    }
    return self;
}

- (void)dealloc {
    [_dataSource release];
    [super dealloc];
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

    _graph = [[[CPTXYGraph alloc] initWithFrame:bounds] autorelease];

    CPTTheme* theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [_graph applyTheme:theme];

    CPTXYPlotSpace* plotSpace = (id)_graph.defaultPlotSpace;
    NSUInteger xMax = [_dataSource maxNumberOfDays];
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(xMax)];
    NSUInteger yMax = [_dataSource maxTapsInOneDay];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(yMax)];

    for (int i = 0; i < [_dataSource numberOfCounters]; ++i) {
        CPTMutableLineStyle* lineStyle = [CPTMutableLineStyle lineStyle];
        lineStyle.lineColor = [_colors objectAtIndex:(i % [_colors count])];
        lineStyle.lineWidth = 1;

        CPTPlotSymbol* plotSymbol = [_symbols objectAtIndex:(i % [_symbols count])];
        plotSymbol.fill = [CPTFill fillWithColor:[_colors objectAtIndex:(i % [_colors count])]];
        plotSymbol.lineStyle = lineStyle;
        plotSymbol.size = CGSizeMake(5, 5);

        CPTScatterPlot* plot = [[[CPTScatterPlot alloc] init] autorelease];
        plot.dataSource = _dataSource;
        plot.identifier = [_dataSource identifierForCounter:i];
        plot.dataLineStyle = lineStyle;
        plot.plotSymbol = plotSymbol;
        [_graph addPlot:plot];
    }

    view.hostedGraph = _graph;
}

@end
