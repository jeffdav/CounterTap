//
//  CTCounterGraphDataSource.h
//  CounterTap
//
//  Created by jorf on 3/24/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CorePlotHeaders/CorePlot-CocoaTouch.h"

@class CTCounter;

@interface CTCounterGraphDataSource : NSObject <CPTPlotDataSource>

@property(nonatomic, readonly) NSArray* data;

- (id)initWithCounters:(NSArray*)counters;

// Accessors for basic properties about the data.

- (NSUInteger)numberOfCounters;
- (NSString*)identifierForCounter:(NSUInteger)counter;

- (NSDate*)minDateInCounter:(CTCounter*)counter;
- (NSDate*)maxDateInCounter:(CTCounter*)counter;

- (NSUInteger)numberOfDaysInCounter:(CTCounter*)counter;
- (NSUInteger)maxTapsInOneDayForCounter:(CTCounter*)counter;

@end
