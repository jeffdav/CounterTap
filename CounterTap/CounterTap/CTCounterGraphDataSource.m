//
//  CTCounterGraphDataSource.m
//  CounterTap
//
//  Created by jorf on 3/24/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CTCounterGraphDataSource.h"

#import "CTCounter.h"

@interface CTCounterGraphDataSource () {
  @private
    NSMutableDictionary* _idMap;
}

// Internal helpers.
- (NSUInteger)tapsInCounter:(CTCounter*)counter onDate:(NSDate*)date;
- (CTCounter*)counterForIdentifier:(NSString*)identifier;
- (NSDate*)roundDate:(NSDate*)date;
- (int)daysBetween:(NSDate*)startDate and:(NSDate*)endDate;
- (NSDate*)dateForCounter:(CTCounter*)counter atIndex:(NSUInteger)index;
@end

@implementation CTCounterGraphDataSource

@synthesize data = _data;

- (id)initWithCounters:(NSArray *)counters {
    if (self = [super init]) {
        _data = [counters retain];
        _idMap = [[NSMutableDictionary alloc] initWithCapacity:[counters count]];
    }
    return self;
}

- (void)dealloc {
    [_data release];
    [_idMap release];
    [super dealloc];
}

- (NSUInteger)numberOfCounters {
    return [_data count];
}

- (NSString*)identifierForCounter:(NSUInteger)counter {
    CTCounter* ctr = (id)[_data objectAtIndex:counter];

    // Cache this mapping for easy lookup later.
    [_idMap setObject:[NSNumber numberWithInt:counter] forKey:ctr.title];

    return ctr.title;
}

- (NSDate*)minDateInCounter:(CTCounter*)counter {
    CTTap* tap = [counter.taps objectAtIndex:0];
    NSDate* date = [NSDate dateWithTimeIntervalSinceReferenceDate:tap.time];
    return [self roundDate:date];
}

- (NSDate*)maxDateInCounter:(CTCounter*)counter {
    CTTap* tap = [counter.taps lastObject];
    NSDate* date = [NSDate dateWithTimeIntervalSinceReferenceDate:tap.time];
    return [self roundDate:date];
}

- (NSUInteger)numberOfDaysInCounter:(CTCounter *)counter {
    return [self daysBetween:[self minDateInCounter:counter] and:[self maxDateInCounter:counter]];
}

- (NSUInteger)maxTapsInOneDayForCounter:(CTCounter *)counter {
    NSUInteger max = 0;
    for (NSUInteger i = 0; i < [self numberOfDaysInCounter:counter]; ++i) {
        max = MAX(max, [self tapsInCounter:counter onDate:[self dateForCounter:counter atIndex:i]]);
    }
    return max;
}

- (NSUInteger)maxTapsInOneDay {
    NSUInteger max = 0;
    for (CTCounter* counter in _data) {
        max = MAX(max, [self maxTapsInOneDayForCounter:counter]);
    }
    return max;
}

- (NSUInteger)maxNumberOfDays {
    NSUInteger max = 0;
    for (CTCounter* counter in _data) {
        max = MAX(max, [self numberOfDaysInCounter:counter]);
    }
    return max;
}

#pragma mark - Internal

- (NSUInteger)tapsInCounter:(CTCounter*)counter onDate:(NSDate*)date {
    __block NSDate* endOfDay = [date dateByAddingTimeInterval:kSecondsInDay];
    NSIndexSet* indexes = [counter.taps indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        CTTap* tap = obj;
        NSDate* tapDate = [NSDate dateWithTimeIntervalSinceReferenceDate:tap.time];
        if ([tapDate compare:date] == NSOrderedAscending) return NO;
        if ([tapDate compare:endOfDay] == NSOrderedDescending) return NO;
        return YES;
    }];

    return [indexes count];
}

- (CTCounter*)counterForIdentifier:(NSString*)identifier {
    NSUInteger index = [[_idMap objectForKey:identifier] intValue];
    return [_data objectAtIndex:index];
}

// Returns a date with HH:MM:SS removed (set to midnight).
- (NSDate*)roundDate:(NSDate*)date {
    unsigned int flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:flags fromDate:date];
    return [calendar dateFromComponents:components];
}

- (int)daysBetween:(NSDate*)startDate and:(NSDate*)endDate {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSDayCalendarUnit fromDate:startDate toDate:endDate options:0];
    return [components day] + 1;
}

- (NSDate*)dateForCounter:(CTCounter*)counter atIndex:(NSUInteger)index {
    NSDateComponents* components = [[[NSDateComponents alloc] init] autorelease];
    [components setDay:index];

    NSCalendar* calendar = [NSCalendar currentCalendar];
    return [calendar dateByAddingComponents:components toDate:[self minDateInCounter:counter] options:0];
}

#pragma mark - CPTPlotDataSource

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    CTCounter* counter = [self counterForIdentifier:(id)plot.identifier];
    if ([counter.taps count] == 0) {
        return 0;
    }

    return [self daysBetween:[self minDateInCounter:counter] and:[self maxDateInCounter:counter]];
}

- (NSNumber*)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
    CTCounter* counter = [self counterForIdentifier:(id)plot.identifier];
    switch (fieldEnum) {
        case CPTScatterPlotFieldX: {
            NSNumber* x = [NSNumber numberWithUnsignedInteger:idx];
            return x;
        }

        case CPTScatterPlotFieldY: {
            NSNumber* y = [NSNumber numberWithUnsignedInteger:[self tapsInCounter:counter onDate:[self dateForCounter:counter atIndex:idx]]];
            return y;
        }
    }

    NSAssert(NO, @"numberForPlot:field:recordIndex: unknown fieldEnum.");
    return 0;
}

@end
