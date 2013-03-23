//
//  CTCounter.h
//  CounterTap
//
//  Created by jorf on 3/16/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

@interface CTTap : NSObject <NSCoding>

@property(nonatomic,readonly) CFAbsoluteTime time;

@end

@interface CTCounter : NSObject <NSCoding>

@property(nonatomic,copy) NSString* title;
@property(nonatomic,readonly) NSInteger count;
@property(nonatomic,readonly) NSArray* taps;

- (void)addTap;
- (void)addTaps:(NSInteger)tapCount;
- (void)clearTaps;
- (void)removeLastTap;

#pragma mark JSON

- (NSDictionary*)asDictionary;

#pragma mark CSV

+ (NSString*)headerForCSV;
- (NSString*)asRowForCSV;

@end
