//
//  CTCounter.h
//  CounterTap
//
//  Created by jorf on 3/16/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

@interface CTCounter : NSObject <NSCoding>

@property(nonatomic,copy) NSString* title;
@property(nonatomic,assign) NSInteger count;

- (NSDictionary*)asDictionary;

@end
