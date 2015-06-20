//
//  GroupOperationTest.m
//  Operative
//
//  Created by Tom Wilson on 20/06/2015.
//  Copyright (c) 2015 Tom Wilson. All rights reserved.
//

#import "GroupOperationTest.h"

@implementation GroupOperationTest

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        OPBlockOperation *block;
        for (int i = 0; i < 10; i++)
        {
            OPBlockOperation *previous = nil;
            if (block)
                previous = block;
                
            block = [[OPBlockOperation alloc] initWithBlock:^(void(^completion)(void)) {
                NSLog(@"Operation %i", i);
                completion();
            }];
            
            if (previous)
            {
                [block addDependency:previous];
            }
            
            [self addOperation:block];
        }
    }
    return self;
}

@end
