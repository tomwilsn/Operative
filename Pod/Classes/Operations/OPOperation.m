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
#import "OPOperationCondition.h"
#import "OPOperationConditionEvaluator.h"
#import "OPOperationObserver.h"


typedef NS_ENUM(NSUInteger, OPOperationState) {
    /**
     *  The initial state of an operation
     */
    OPOperationStateInitialized,
    /**
     *  The `OPOperation` is ready to begin evaluating conditions.
     */
    OPOperationStatePending,
    /**
     *  The `OPOperation` is evaluating conditions.
     */
    OPOperationStateEvaluatingConditions,
    /**
     *  The `OPOperation`'s conditions have all been satisfied, and it is ready
     *  to execute.
     */
    OPOperationStateReady,
    /**
     *  The `OPOperation` is executing
     */
    OPOperationStateExecuting,
    /**
     *  Execution of the `OPOperation` has finished, but it has not yet notified
     *  the queue of this.
     */
    OPOperationStateFinishing,
    /**
     *  The `OPOperation` has finished executing.
     */
    OPOperationStateFinished
};


@interface OPOperation()


@property (strong, nonatomic, readwrite) NSMutableArray *conditions;

/**
 *  A private property to ensure we only notify the observers one time upon
 *  operation has finished.
 */
@property (assign, nonatomic) BOOL hasFinishedAlready;

/**
 *  A private property used to indicate the state of the operation.
 *  Property is KVO observable.
 */
@property (assign, nonatomic) OPOperationState state;

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
@synthesize state = _state;


#pragma mark - KVO
#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingIsReady
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(state))];
}

+ (NSSet *)keyPathsForValuesAffectingIsExecuting
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(state))];
}

+ (NSSet *)keyPathsForValuesAffectingIsFinished
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(state))];
}


- (void)willEnqueue
{
    [self setState:OPOperationStatePending];
}


#pragma mark - State
#pragma mark -

- (OPOperationState)state
{
    OPOperationState value;
    @synchronized(self) {
        value = _state;
    }
    return value;
}

- (void)setState:(OPOperationState)newState
{
    // Guard against calling if state is currently finished
    if (_state == OPOperationStateFinished) {
        return;
    }
    
    NSAssert(_state != newState, @"Performing invalid cyclic state transition.");
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(state))];
    
    @synchronized(self) {
        _state = newState;
    }

    [self didChangeValueForKey:NSStringFromSelector(@selector(state))];
}

- (void)evaluateConditions
{
    NSAssert([self state] == OPOperationStatePending, @"evaluateConditions was called out-of-order");

    [self setState:OPOperationStateEvaluatingConditions];

    [OPOperationConditionEvaluator evaluateConditions:[self conditions] operation:self completion:^(NSArray *failures) {
        [self.internalErrors addObjectsFromArray:failures];
        [self setState:OPOperationStateReady];
    }];
}


#pragma mark - Overrides
#pragma mark -

- (BOOL)isReady
{
    switch ([self state]) {
        case OPOperationStateInitialized:
            return [self isCancelled];

        case OPOperationStatePending:
            if ([self isCancelled]) {
                return YES;
            }
            if ([super isReady]) {
                [self evaluateConditions];
            }
            return NO;

        case OPOperationStateReady:
            return [super isReady] || [self isCancelled];

        default:
            return NO;
    }
}

- (BOOL)isExecuting
{
    return [self state] == OPOperationStateExecuting;
}

- (BOOL)isFinished
{
    return [self state] == OPOperationStateFinished;
}


#pragma mark - QOS
#pragma mark -

- (BOOL)userInitiated
{
    return [self qualityOfService] == NSOperationQualityOfServiceUserInitiated;
}

- (void)setUserInitiated:(BOOL)userInitiated
{
    NSAssert([self state] < OPOperationStateExecuting, @"Cannot modify userInitiated after execution has begun.");
    
    [self setQualityOfService:userInitiated ? NSOperationQualityOfServiceUserInitiated : NSOperationQualityOfServiceUtility];
}


#pragma mark - Conditions
#pragma mark -

- (void)addCondition:(id <OPOperationCondition>)condition
{
    NSAssert([self state] < OPOperationStateEvaluatingConditions, @"Cannot modify conditions after execution has begun.");

    [self.conditions addObject:condition];
}


#pragma mark - Observers
#pragma mark -

- (void)addObserver:(id <OPOperationObserver>)observer
{
    NSAssert([self state] < OPOperationStateExecuting, @"Cannot modify observers after execution has begun.");

    [self.observers addObject:observer];
}


- (void)addDependency:(NSOperation *)operation
{
    NSAssert([self state] < OPOperationStateExecuting, @"Dependencies cannot be modified after execution has begun.");

    [super addDependency:operation];
}


#pragma mark - Execution and Cancellation
#pragma mark -

- (void)start
{
    // [NSOperation start]; contains important logic that shouldn't be bypassed.
    [super start];

    // If the operation has been cancelled, we still need to enter the "Finished" state.
    if ([self isCancelled]) {
        [self finish];
    }
}

- (void)main
{
    NSAssert([self state] == OPOperationStateReady, @"This operation must be performed on an operation queue.");

    if ([self.internalErrors count] == 0 && ![self isCancelled]) {

        [self setState:OPOperationStateExecuting];

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
        [self setState:OPOperationStateFinishing];

        NSArray *combinedErrors = [self.internalErrors arrayByAddingObjectsFromArray:errors];

        [self finishedWithErrors:combinedErrors];

        for (id <OPOperationObserver>observer in [self observers]) {
            [observer operation:self didFinishWithErrors:combinedErrors];
        }

        [self setState:OPOperationStateFinished];
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

    _state = OPOperationStateInitialized;
    _observers = [[NSMutableArray alloc] init];
    _conditions = [[NSMutableArray alloc] init];

    _internalErrors = [[NSMutableArray alloc] init];

    return self;
}

@end
