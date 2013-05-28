//
//  CTCounter.m
//  CounterTap
//
//  Created by jorf on 3/16/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CTCounter.h"

@interface CTTap ()
@end

NSString* const CTTap_TimeKey = @"CTTapTimeKey";

@implementation CTTap

@synthesize time = _time;

- (id)init {
    if (self = [super init]) {
        _time = CFAbsoluteTimeGetCurrent();
    }
    return self;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"{ \"time\": %f }", _time];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _time = [aDecoder decodeDoubleForKey:CTTap_TimeKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeDouble:_time forKey:CTTap_TimeKey];
}

@end

NSString* const CTCounter_TitleKey = @"CTCounterTitleKey";
NSString* const CTCounter_TapsKey = @"CTCounterTapsKey";

@interface CTCounter () {
    NSMutableArray* _taps;
}
@end

@implementation CTCounter

@synthesize title = _title;
@synthesize taps = _taps;

- (id)init {
    if (self = [super init]) {
        _taps = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_title release];
    [_taps release];
    [super dealloc];
}

- (NSInteger)count {
    return [_taps count];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"{ \"title\": \"%@\", \"count\": %d, \"taps\": %@ }", _title, [_taps count], _taps];
}

- (void)addTap {
    [_taps addObject:[[[CTTap alloc] init] autorelease]];
}

- (void)addTaps:(NSInteger)tapCount {
    for (int i = 0; i < tapCount; ++i) {
        [self addTap];
    }
}

- (void)clearTaps {
    [_taps removeAllObjects];
}

- (void)removeLastTap {
    [_taps removeLastObject];
}

#pragma mark - JSON

- (NSDictionary*)asDictionary {
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[_taps count]];
    for (CTTap* tap in _taps) {
        [array addObject:[NSNumber numberWithDouble:tap.time]];
    }
    return @{ @"title" : _title, @"count" : @([_taps count]), @"taps" : array };
}

#pragma mark - CSV

+ (NSString*)headerForCSV {
    return @"Title,Count\r\n";
}

- (NSString*)asRowForCSV {
    return [NSString stringWithFormat:@"%@,%d\r\n", _title, self.count];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _title = [[aDecoder decodeObjectForKey:CTCounter_TitleKey] retain];
        _taps = [[aDecoder decodeObjectForKey:CTCounter_TapsKey] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_title forKey:CTCounter_TitleKey];
    [aCoder encodeObject:_taps forKey:CTCounter_TapsKey];
}

@end
