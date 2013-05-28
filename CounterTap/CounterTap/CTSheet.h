//
//  CTSheet.h
//  CounterTap
//
//  Created by jorf on 5/27/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

@interface CTSheet : NSObject <NSCoding>

@property(nonatomic,copy) NSString* title;
@property(nonatomic,readonly) NSArray* counters;

- (void)addCounterWithTitle:(NSString*)title;
- (void)clearCounters;

#pragma mark JSON

- (NSDictionary*)asDictionary;

@end
