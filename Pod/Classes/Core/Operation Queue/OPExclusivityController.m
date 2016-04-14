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

@property (strong, nonatomic) NSMutableDictionary *operations;

#if OS_OBJECT_USE_OBJC
@property (strong, nonatomic) dispatch_queue_t serialQueue;
#else
@property (assign, nonatomic) dispatch_queue_t serialQueue;
#endif

@end

@implementation OPExclusivityController


#pragma mark - Add & Remove Operations
#pragma mark -

- (void)addOperation:(OPOperation *)operation categories:(NSArray *)categories
{
    dispatch_sync([self serialQueue], ^{
        for (NSString *category in categories) {
            [self noqueue_addOperation:operation category:category];
        }
    });
}


- (void)removeOperation:(OPOperation *)operation categories:(NSArray *)categories
{
    dispatch_sync([self serialQueue], ^{
        for (NSString *category in categories) {
            [self noqueue_removeOperation:operation category:category];
        }
    });
}


#pragma mark - Operation Management
#pragma mark -

- (void)noqueue_addOperation:(OPOperation *)operation category:(NSString *)category
{
    NSArray *operationsWithThisCategory = self.operations[category] ?: @[];

    if ([operationsWithThisCategory count]) {
        OPOperation *op = [operationsWithThisCategory lastObject];
        [operation addDependency:op];
        
        // condition evaluator should wait for mutually exclusive operation too
        [operation.conditionEvaluationOperation addDependency:op];
    }

    operationsWithThisCategory = [operationsWithThisCategory arrayByAddingObject:operation];

    self.operations[category] = operationsWithThisCategory;
}

- (void)noqueue_removeOperation:(OPOperation *)operation category:(NSString *)category
{
    if (!self.operations[category]) {
        return;
    }

    NSArray *operationsWithThisCategory = self.operations[category];

    NSUInteger index = [operationsWithThisCategory indexOfObject:operation];
    if (index != NSNotFound) {
        NSMutableArray *mutableArray = [operationsWithThisCategory mutableCopy];
        [mutableArray removeObjectAtIndex:index];
        operationsWithThisCategory = [NSArray arrayWithArray:mutableArray];
        self.operations[category] = operationsWithThisCategory;
    }
}


#pragma mark - Lifecycle
#pragma mark -

+ (OPExclusivityController *)sharedExclusivityController
{
    static OPExclusivityController *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OPExclusivityController alloc] init];
    });

    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _serialQueue = dispatch_queue_create("Operative.ExclusivityController", DISPATCH_QUEUE_SERIAL);
    _operations = [[NSMutableDictionary alloc] init];

    return self;
}

@end
