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
#import "OPBlockOperation.h"
#import "OPBlockObserver.h"
#import "OPExclusivityController.h"
#import "OPOperationCondition.h"
#import "OPOperationConditionEvaluator.h"


@implementation OPOperationQueue

#pragma mark - Debugging
#pragma mark -

- (NSString *)debugDescription
{
    NSMutableString *mutableString = [[NSMutableString alloc] init];
    NSArray *operations = [[self operations] copy];
    
    NSString *description = [super debugDescription];
    NSString *state = [self isSuspended] ? @"YES" : @"NO";
    
    NSString *result;
    
    for(NSOperation *op in operations)
    {
        NSArray *lines = [[op debugDescription] componentsSeparatedByString:@"\n"];
        
        for(NSString *str in lines)
        {
            [mutableString appendFormat:@"\t%@\n", str];
        }
    }
    
    result = [NSString stringWithFormat:@"%@ { isSuspended = %@ }\n%@", description, state, mutableString];
    
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (void)addOperation:(NSOperation *)operation
{
    if ([operation isKindOfClass:[OPOperation class]]) {
        OPOperation *opOperation = (OPOperation *)operation;

        // Set up a `OPBlockObserver` to invoke the `OPOperationQueueDelegate` method.
        __weak __typeof__(self) weakSelf = self;
        id <OPOperationObserver>observer = [[OPBlockObserver alloc] initWithStartHandler:nil
                                                                          produceHandler:^(__unused OPOperation *anOperation, NSOperation *newOperation) {
                                                                              [weakSelf addOperation:newOperation];
                                                                          }
                                                                           finishHandler:^(OPOperation *anOperation, NSArray *errors) {
                                                                               __typeof__(self) strongSelf = weakSelf;
                                                                               if ([strongSelf delegate] && [strongSelf.delegate respondsToSelector:@selector(operationQueue:operationDidFinish:withErrors:)]) {
                                                                                   [strongSelf.delegate operationQueue:strongSelf operationDidFinish:anOperation withErrors:errors];
                                                                               }
                                                                           }];

        [opOperation addObserver:observer];
        
        /*
         Add conditions evaluation operation.
         
         Previously condition evaluation would happen on Operation level.
         However due to bug discovered in NSOperation we cannot safely manipulate NSOperation.isReady.
         
         Therefore we have to wrap condition evalutor into operation and make it dependency for main operation.
         Evaluation errors are then passed back to main operation before its execution.
         
         Relevant discussions:
         
         1. https://github.com/danthorpe/Operations/issues/175
         2. https://github.com/Kabal/Operative/issues/51
         
         */
        
        if(opOperation.conditions.count)
        {
            __weak OPOperation *weakOperation = opOperation;
            
            OPBlockOperation *evaluationOperation = [[OPBlockOperation alloc] initWithBlock:^(void (^completion)(void)) {
                __strong OPOperation *strongOperation = weakOperation;
                
                [OPOperationConditionEvaluator evaluateConditions:[strongOperation conditions] operation:strongOperation completion:^(NSArray *failures) {
                    if(failures.count) {
                        [strongOperation finishWithErrors:failures];
                    }
                    
                    completion();
                }];
            }];
            
            evaluationOperation.qualityOfService = opOperation.qualityOfService;
            evaluationOperation.name = [NSString stringWithFormat:@"Condition evaluator for %@", [opOperation description]];
            
            // Extract any dependencies needed by this operation
            NSMutableArray *dependencies = [[NSMutableArray alloc] init];
            for (id <OPOperationCondition> condition in [opOperation conditions]) {
                NSOperation *dependency = [condition dependencyForOperation:opOperation];
                if (dependency) {
                    [dependencies addObject:dependency];
                    
                    [evaluationOperation addDependency:dependency];
                }
            }
            
            // add evaluator into dependencies
            [dependencies addObject:evaluationOperation];
            
            // operation should depend on evaluator
            [opOperation addDependency:evaluationOperation];
            
            // With condition dependencies added, we can now see if this needs
            // dependencies to enforce mutual exclusivity.
            NSMutableArray *concurrencyCategories = [[NSMutableArray alloc] init];
            for (id<OPOperationCondition> condition in [opOperation conditions]) {
                if (condition.isMutuallyExclusive) {
                    [concurrencyCategories addObject:condition.name];
                }
            }
            
            if ([concurrencyCategories count] > 0)
            {
                // Set up the mutual exclusivity dependencies.
                OPExclusivityController *exclusivityController = [OPExclusivityController sharedExclusivityController];
                
                NSSet *previousMutuallyExclusiveOperations = [exclusivityController addOperation:opOperation categories:concurrencyCategories];
                
                for(NSOperation *previousExclusiveOp in previousMutuallyExclusiveOperations) {
                    for(NSOperation *dependency in dependencies) {
                        [dependency addDependency:previousExclusiveOp];
                    }
                    
                    [opOperation addDependency:previousExclusiveOp];
                }
                
                OPBlockObserver *blockObserver = [[OPBlockObserver alloc] initWithStartHandler:nil
                                                                                produceHandler:nil
                                                                                 finishHandler:^(OPOperation *anOperation, __unused NSArray *errors) {
                                                                                     [exclusivityController removeOperation:anOperation categories:concurrencyCategories];
                                                                                 }];
                [opOperation addObserver:blockObserver];
            }
            
            [self addOperations:dependencies waitUntilFinished:NO];
        }

        /**
         *  Indicate to the operation that we've finished our extra work on it
         *  and it's now it a state where it can proceed with evaluating conditions,
         *  if appropriate.
         */
        [opOperation willEnqueue];
    }
    else {
        /**
         *  For regular `NSOperation`s, we'll manually call out to the queue's
         *  delegate we don't want to just capture "operation" because that
         *  would lead to the operation strongly referencing itself and that's
         *  the pure definition of a memory leak.
         */
        __weak __typeof__(self) weakSelf = self;
        __weak NSOperation *weakOperation = operation;

        [operation setCompletionBlock:^(void) {
            __typeof__(self) strongSelf = weakSelf;
            NSOperation *strongOperation = weakOperation;
            if ([strongSelf delegate] && [strongSelf.delegate respondsToSelector:@selector(operationQueue:operationDidFinish:withErrors:)]) {
                [strongSelf.delegate operationQueue:strongSelf operationDidFinish:strongOperation withErrors:@[]];
            }
        }];
    }

    if ([self delegate] && [self.delegate respondsToSelector:@selector(operationQueue:willAddOperation:)]) {
        [self.delegate operationQueue:self willAddOperation:operation];
    }

    [super addOperation:operation];
}

- (void)addOperations:(NSArray *)operations waitUntilFinished:(BOOL)wait
{
    /**
     *  The base implementation of this method does not call `-addOperation:`,
     *  so we'll call it ourselves.
     */
    for (NSOperation *operation in operations) {
        [self addOperation:operation];
    }

    if (wait) {
        for (NSOperation *operation in operations) {
            [operation waitUntilFinished];
        }
    }
}

@end
