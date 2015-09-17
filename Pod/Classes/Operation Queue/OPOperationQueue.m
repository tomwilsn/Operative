// OPOperationQueue.m
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

#import "OPOperationQueue.h"
#import "OPOperation.h"
#import "OPBlockObserver.h"
#import "OPExclusivityController.h"
#import "OPOperationCondition.h"

@implementation OPOperationQueue

- (void) addOperation:(NSOperation *)operation
{
    if ([operation isKindOfClass:[OPOperation class]])
    {
        OPOperation *opOperation = (OPOperation *)operation;

        id <OPOperationObserver> observer = [[OPBlockObserver alloc] initWithStartHandler:nil
                                                                           produceHandler:^(OPOperation *operation, NSOperation *newOperation) {
                                                                               [self addOperation:newOperation];
                                                                           }
                                                                            finishHandler:^(OPOperation *operation, NSArray *errors) {
                                                                                if ([self delegate] && [self.delegate respondsToSelector:@selector(operationQueue:operationDidFinish:withErrors:)]) {
                                                                                    [self.delegate operationQueue:self operationDidFinish:operation withErrors:errors];
                                                                                }
                                                                            }];
        
        [opOperation addObserver:observer];
        
        // Extract any dependencies needed by this operation
        NSMutableArray *dependencies = [[NSMutableArray alloc] init];
        for (id<OPOperationCondition> condition in opOperation.conditions)
        {
            NSOperation *dependency = [condition dependencyForOperation:opOperation];
            if (dependency)
            {
                [dependencies addObject:dependency];
            }
        }
        
        for (NSOperation *dependency in dependencies)
        {
            [opOperation addDependency:dependency];
            [self addOperation:dependency];
        }
        
        // With condition dependencies added, we can now see if this needs
        // dependencies to enforce mutual exclusivity.
        NSMutableArray *concurrencyCategories = [[NSMutableArray alloc] init];
        for (id<OPOperationCondition> condition in opOperation.conditions)
        {
            if (condition.isMutuallyExclusive)
            {
                [concurrencyCategories addObject:condition.name];
            }
        }
        
        if (concurrencyCategories.count > 0)
        {
            OPExclusivityController *exclusivityController = [OPExclusivityController sharedExclusivityController];
            
            [exclusivityController addOperation:opOperation categories:concurrencyCategories];
            
            [opOperation addObserver:[[OPBlockObserver alloc] initWithStartHandler:nil produceHandler:nil finishHandler:^(OPOperation *operation, NSArray *errors) {
                [exclusivityController removeOperation:opOperation categories:concurrencyCategories];
            }]];
        }
        
        [opOperation willEnqueue];
    }
    else
    {
        __weak __typeof__(self) weakSelf = self;
        __weak NSOperation *weakOperation = operation;

        operation.completionBlock = ^(void) {
            __typeof__(self) strongSelf = weakSelf;
            NSOperation *strongOperation = weakOperation;
            if ([strongSelf delegate] && [strongSelf.delegate respondsToSelector:@selector(operationQueue:operationDidFinish:withErrors:)]) {
                [strongSelf.delegate operationQueue:strongSelf operationDidFinish:strongOperation withErrors:@[]];
            }
        };
    }
    
    [self.delegate operationQueue:self willAddOperation:operation];
    [super addOperation:operation];
}

- (void) addOperations:(NSArray *)operations waitUntilFinished:(BOOL)wait
{
    for (NSOperation *operation in operations)
    {
        [self addOperation:operation];
    }
    
    if (wait)
    {
        for (NSOperation *operation in operations)
        {
            [operation waitUntilFinished];
        }
    }
}

@end
