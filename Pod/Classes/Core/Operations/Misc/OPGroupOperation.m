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
#import "OPOperationQueue.h"


@interface OPGroupOperation() <OPOperationQueueDelegate>

- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 *  Common initialized elements used in both `-init` & `-initWithOperations:`
 */
- (void)commonInit;

@property (strong, nonatomic) OPOperationQueue *internalQueue;
@property (strong, nonatomic) NSBlockOperation *finishingOperation;

@property (strong, nonatomic) NSMutableArray *aggregatedErrors;

@end


@implementation OPGroupOperation

#pragma mark - Debugging
#pragma mark -

- (NSString *)debugDescription
{
    NSMutableString *mutableString = [[NSMutableString alloc] init];
    NSString *description = [super debugDescription];
    NSString *result;
    
    NSArray *lines = [[self.internalQueue debugDescription] componentsSeparatedByString:@"\n"];
    
    for(NSString *str in lines)
    {
        [mutableString appendFormat:@"\t%@\n", str];
    }
    
    result = [description stringByAppendingFormat:@"\n%@", mutableString];
    
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

#pragma mark -
#pragma mark -

- (void)addOperation:(NSOperation *)operation
{
    [self.internalQueue addOperation:operation];
}

- (void)addOperations:(NSArray *)operations
{
    [self.internalQueue addOperations:operations waitUntilFinished:NO];
}

- (void)aggregateError:(NSError *)error
{
    [self.aggregatedErrors addObject:error];
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors
{
    // No-op
    // For use by subclass.
}


#pragma mark - Overrides
#pragma mark -

- (void)cancel
{
    [self.internalQueue cancelAllOperations];
    [super cancel];
}

- (void)execute
{
    [self.internalQueue setSuspended:NO];
    [self.internalQueue addOperation:self.finishingOperation];
}


#pragma mark - OPOperationQueueDelegate
#pragma mark -

- (void)operationQueue:(OPOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation
{
    NSAssert(![self.finishingOperation isFinished] && ![self.finishingOperation isExecuting], @"Cannot add new operations to a group after the group has completed");

    if ([self finishingOperation] != operation) {
        [self.finishingOperation addDependency:operation];
    }
}

- (void)operationQueue:(OPOperationQueue *)operationQueue operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors
{
    [self.aggregatedErrors addObjectsFromArray:errors];

    if ([self finishingOperation] == operation) {
        [self.internalQueue setSuspended:YES];
        [self finishWithErrors:[self aggregatedErrors]];
    } else {
        [self operationDidFinish:operation withErrors:errors];
    }
}


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (instancetype)initWithOperations:(NSArray *)operations
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    for (NSOperation *operation in operations) {
        [_internalQueue addOperation:operation];
    }
    
    return self;
}


#pragma mark - Private
#pragma mark -

- (void)commonInit
{
    OPOperationQueue *queue = [[OPOperationQueue alloc] init];
    [queue setSuspended:YES];
    [queue setDelegate:self];
    
    _internalQueue = queue;
    
    _finishingOperation = [NSBlockOperation blockOperationWithBlock:^{}];
    
    _aggregatedErrors = [[NSMutableArray alloc] init];
}

@end
