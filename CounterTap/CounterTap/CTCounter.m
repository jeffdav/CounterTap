//
//  CTCounter.m
//  CounterTap
//
//  Created by jorf on 3/16/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CTCounter.h"

NSString* const CTCounter_TitleKey = @"CTCounterTitleKey";
NSString* const CTCounter_CountKey = @"CTCounterCountKey";

@implementation CTCounter

@synthesize title = _title;
@synthesize count = _count;

- (void)dealloc {
    [_title release];
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"{ \"title\": \"%@\", \"count\": %d", _title, _count];
}

#pragma mark - NSCoder

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.title = [aDecoder decodeObjectForKey:CTCounter_TitleKey];
        self.count = [aDecoder decodeIntegerForKey:CTCounter_CountKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_title forKey:CTCounter_TitleKey];
    [aCoder encodeInteger:_count forKey:CTCounter_CountKey];
}

@end
