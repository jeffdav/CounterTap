//
//  CTSheet.m
//  CounterTap
//
//  Created by jorf on 5/27/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CTSheet.h"

#import "CTCounter.h"

NSString* const CTSheet_TitleKey = @"CTSheetTitleKey";
NSString* const CTSheet_CountersKey = @"CTSheetTapsKey";

@interface CTSheet () {
    NSMutableArray* _counters;
}
@end

@implementation CTSheet

@synthesize title = _title;
@synthesize counters = _counters;

- (id)init {
    if (self = [super init]) {
        _counters = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_counters release];
    [_title release];
    [super dealloc];
}

- (void)addCounterWithTitle:(NSString *)title {
    CTCounter* counter = [[[CTCounter alloc] init] autorelease];
    counter.title = title;
    [_counters addObject:counter];
}

- (void)clearCounters {
    [_counters removeAllObjects];
}

#pragma mark - JSON

- (NSDictionary*)asDictionary {
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[_counters count]];
    for (CTCounter* counter in _counters) {
        [array addObject:[counter asDictionary]];
    }
    return @{ @"title" : _title, @"counters" : array };
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder*)aDecoder {
    if (self = [super init]) {
        _title = [[aDecoder decodeObjectForKey:CTSheet_TitleKey] retain];
        _counters = [[aDecoder decodeObjectForKey:CTSheet_CountersKey] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_title forKey:CTSheet_TitleKey];
    [aCoder encodeObject:_counters forKey:CTSheet_CountersKey];
}

@end
