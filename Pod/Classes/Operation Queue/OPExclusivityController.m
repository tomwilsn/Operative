// OPExclusivityController.m
// Copyright (c) 2015 Tom Wilson <tom@toms-stuff.net>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "OPExclusivityController.h"

@interface OPExclusivityController()
{
    dispatch_queue_t serialQueue;
}

@property (strong, nonatomic) NSMutableDictionary *operations;

@end

@implementation OPExclusivityController

+ (instancetype) sharedExclusivityController {
    static id _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        serialQueue = dispatch_queue_create("OPOperations.ExclusivityController", DISPATCH_QUEUE_SERIAL);
        _operations = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) addOperation:(OPOperation *) operation categories:(NSArray *) categories
{
    dispatch_sync(serialQueue, ^{
        for (NSString *category in categories)
        {
            [self noqueue_addOperation:operation category:category];
        }
    });
}

- (void) removeOperation:(OPOperation *) operation categories:(NSArray *) categories
{
    dispatch_sync(serialQueue, ^{
        for (NSString *category in categories)
        {
            [self noqueue_removeOperation:operation category:category];
        }
    });
}

#pragma mark Operation Management

- (void) noqueue_addOperation:(OPOperation *) operation category:(NSString *) category
{
    NSMutableArray *operationsWithThisCategory = _operations[category];
    if (!operationsWithThisCategory)
    {
        operationsWithThisCategory = [[NSMutableArray alloc] init];
        _operations[category] = operationsWithThisCategory;
    }
    else if (operationsWithThisCategory.count > 0)
    {
        OPOperation *last = operationsWithThisCategory.lastObject;
        [operation addDependency:last];
    }
    
    [operationsWithThisCategory addObject:operation];
}

- (void) noqueue_removeOperation:(OPOperation *) operation category:(NSString *) category
{
    NSMutableArray *operationsWithThisCategory = _operations[category];

    NSUInteger index = [operationsWithThisCategory indexOfObject:operation];
    if (index != NSNotFound)
    {
        [operationsWithThisCategory removeObjectAtIndex:index];
    }
}

@end
