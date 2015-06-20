// OPGroupOperation.m
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

#import "OPGroupOperation.h"
#import <Foundation/Foundation.h>

@interface OPGroupOperation() <OPOperationQueueDelegate>

@property (strong, nonatomic) OPOperationQueue *internalQueue;
@property (strong, nonatomic) NSBlockOperation *finishingOperation;

@property (strong, nonatomic) NSMutableArray *aggregatedErrors;

@end

@implementation OPGroupOperation

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _internalQueue = [[OPOperationQueue alloc] init];
        _internalQueue.suspended = YES;
        _internalQueue.delegate = self;
        
        _finishingOperation = [NSBlockOperation blockOperationWithBlock:^{}];
        
        _aggregatedErrors = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype) initWithOperations:(NSArray *) operations
{
    self = [super init];
    
    if (self)
    {
        [_internalQueue addOperations:operations waitUntilFinished:NO];
    }
    return self;
}

- (void) cancel
{
    [self.internalQueue cancelAllOperations];
    [super cancel];
}

- (void) execute
{
    self.internalQueue.suspended = false;
    [self.internalQueue addOperation:self.finishingOperation];
}

- (void) addOperation:(NSOperation *) operation
{
    [self.internalQueue addOperation:operation];
}

- (void) aggregateError:(NSError *) error
{
    [self.aggregatedErrors addObject:error];
}

- (void) operationDidFinish:(NSOperation *) operation withErrors:(NSArray *) errors
{
    // for user by subclassers
}

#pragma mark - OPOperationQueueDelegate

- (void) operationQueue:(OPOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation
{
    NSAssert(!self.finishingOperation.finished && !self.finishingOperation.isExecuting, @"cannot add new operations to a group after the group has completed");
    
    if (operation != self.finishingOperation)
    {
        [self.finishingOperation addDependency:operation];
    }
}

- (void) operationQueue:(OPOperationQueue *)operationQueue operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors
{
    [self.aggregatedErrors addObjectsFromArray:errors];
    
    if (operation == self.finishingOperation)
    {
        self.internalQueue.suspended = YES;
        [self finishWithErrors:self.aggregatedErrors];
    }
    else
    {
        [self operationDidFinish:operation withErrors:errors];
    }
}

@end
