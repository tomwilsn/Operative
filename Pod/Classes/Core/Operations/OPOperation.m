// OPOperation.m
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

#import "OPOperation.h"
#import "OPBlockOperation.h"
#import "OPOperationCondition.h"
#import "OPOperationConditionEvaluator.h"
#import "OPOperationObserver.h"

@interface OPOperation()

@property (nonatomic, getter = isFinished, readwrite)  BOOL finished;
@property (nonatomic, getter = isExecuting, readwrite) BOOL executing;

@property (strong, nonatomic, readwrite) NSMutableArray *conditions;

/**
 *  A private property to ensure we only notify the observers one time upon
 *  operation has finished.
 */
@property (assign, nonatomic) BOOL hasFinishedAlready;

/**
 *  A private property used to store `NSError` objects in the event that
 *  the operation encounters an error.
 */
@property (strong, nonatomic) NSMutableArray *internalErrors;

/**
 *  A private property used to store objects conforming to the
 *  `OPOperationObserver` protocol. Observers will be informed of
 *  the `OPOperation`'s state as the operation transitions between them.
 */
@property (strong, nonatomic) NSMutableArray *observers;

@end


@implementation OPOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark - Debugging
#pragma mark -

- (NSString *)debugDescription {
    NSString *stateString = @"Pending";
    
    if([self isExecuting]) {
        stateString = @"Executing";
    }
    else if([self isFinished]) {
        stateString = @"Finished";
    }
    else if([self isReady])
    {
        stateString = @"Ready";
    }
    
    return [NSString stringWithFormat:@"%@ (%@)", [super debugDescription], stateString];
}

- (void)willEnqueue
{
    // no-op
}


#pragma mark - Overrides
#pragma mark -

- (BOOL)isExecuting {
    @synchronized(self) {
        return _executing;
    }
}

- (BOOL)isFinished {
    @synchronized(self) {
        return _finished;
    }
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    @synchronized(self) {
        if (_executing != executing) {
            _executing = executing;
        }
    }
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    @synchronized(self) {
        if (_finished != finished) {
            _finished = finished;
        }
    }
    [self didChangeValueForKey:@"isFinished"];
}


#pragma mark - QOS
#pragma mark -

- (BOOL)userInitiated
{
    return [self qualityOfService] == NSOperationQualityOfServiceUserInitiated;
}

- (void)setUserInitiated:(BOOL)userInitiated
{
    NSAssert(!self.isExecuting && !self.isFinished, @"Cannot modify userInitiated after execution has begun.");
    
    [self setQualityOfService:userInitiated ? NSOperationQualityOfServiceUserInitiated : NSOperationQualityOfServiceUtility];
}


#pragma mark - Conditions
#pragma mark -

- (void)addCondition:(id <OPOperationCondition>)condition
{
    NSAssert(!self.isExecuting && !self.isFinished, @"Cannot modify conditions after execution has begun.");

    [self.conditions addObject:condition];
}

- (NSOperation *)conditionEvaluationOperation
{
    NSAssert(!self.isExecuting && !self.isFinished, @"Cannot issue condition evaluation operation for already executing or finished operations.");
    
    __weak __typeof__(self) weakSelf = self;
    
    if(self.conditions.count == 0) {
        return nil;
    }
    
    OPBlockOperation *evaluationOperation = [[OPBlockOperation alloc] initWithBlock:^(void (^completion)(void)) {
        __strong __typeof__(self) strongSelf = weakSelf;
        
        [OPOperationConditionEvaluator evaluateConditions:[strongSelf conditions] operation:strongSelf completion:^(NSArray *failures) {
            [strongSelf.internalErrors addObjectsFromArray:failures];
            
            completion();
        }];
    }];
    
    evaluationOperation.qualityOfService = self.qualityOfService;
    evaluationOperation.name = [NSString stringWithFormat:@"Condition evaluator for %@", [self description]];
    
    return evaluationOperation;
}


#pragma mark - Observers
#pragma mark -

- (void)addObserver:(id <OPOperationObserver>)observer
{
    NSAssert(!self.isExecuting && !self.isFinished, @"Cannot modify observers after execution has begun.");

    [self.observers addObject:observer];
}


- (void)addDependency:(NSOperation *)operation
{
    NSAssert(!self.isExecuting && !self.isFinished, @"Dependencies cannot be modified after execution has begun.");

    [super addDependency:operation];
}


#pragma mark - Execution and Cancellation
#pragma mark -

- (void)start
{
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    self.executing = YES;
    
    [self main];
}

- (void)main
{
    if ([self.internalErrors count] == 0 && ![self isCancelled]) {
        
        for (id <OPOperationObserver>observer in [self observers]) {
            [observer operationDidStart:self];
        }

        [self execute];

    } else {
        [self finish];
    }
}

- (void)execute
{
    NSLog(@"%@ must override -execute.", NSStringFromClass([self class]));

    [self finishWithError:nil];
}

- (void)cancel {
    [super cancel];
    
    if([self isFinished]) {
        return;
    }
}

- (void)cancelWithError:(NSError *)error
{
    if (error) {
        [self.internalErrors addObject:error];
    }

    [self cancel];
}

- (void)produceOperation:(NSOperation *)operation
{
    for (id <OPOperationObserver>observer in [self observers]) {
        [observer operation:self didProduceOperation:operation];
    }
}


#pragma mark - Finishing
#pragma mark -

- (void)finish;
{
    [self finishWithError:nil];
}

- (void)finishWithError:(NSError *)error
{
    [self finishWithErrors:error ? @[error] : @[]];
}

- (void)finishWithErrors:(NSArray *)errors
{
    if (![self hasFinishedAlready]) {
        [self setHasFinishedAlready:YES];

        NSArray *combinedErrors = [self.internalErrors arrayByAddingObjectsFromArray:errors];

        [self finishedWithErrors:combinedErrors];

        for (id <OPOperationObserver>observer in [self observers]) {
            [observer operation:self didFinishWithErrors:combinedErrors];
        }
        
        self.executing = NO;
        self.finished  = YES;
    }
}

- (void)finishedWithErrors:(NSArray *)errors
{
    // No-op
}

- (void)waitUntilFinished
{
    NSAssert(NO, @"I'm pretty sure you don't want to do this.");
}


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _executing = NO;
    _finished = NO;

    _observers = [[NSMutableArray alloc] init];
    _conditions = [[NSMutableArray alloc] init];

    _internalErrors = [[NSMutableArray alloc] init];
    
    return self;
}

@end
