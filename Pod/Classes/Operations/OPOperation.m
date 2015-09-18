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
#import "OPOperationObserver.h"
#import "OPOperationConditionEvaluator.h"
#import "OPOperationCondition.h"

typedef NS_ENUM(NSUInteger, OPOperationState) {
    OPOperationStateInitialized,
    OPOperationStatePending,
    OPOperationStateEvaluatingConditions,
    OPOperationStateReady,
    OPOperationStateExecuting,
    OPOperationStateFinishing,
    OPOperationStateFinished,
    OPOperationStateCancelled,
};


@interface OPOperation()

@property (assign, nonatomic) OPOperationState state;

@property (strong, nonatomic) NSMutableArray *observers;

@property (strong, nonatomic) NSMutableArray *internalErrors;

@property (assign, nonatomic) BOOL hasFinishedAlready;

@property (strong, nonatomic) NSMutableArray *conditions;

@end


@implementation OPOperation

- (instancetype) init
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

- (void) willEnqueue
{
    self.state = OPOperationStatePending;
}

#pragma mark - KVO

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

+ (NSSet *)keyPathsForValuesAffectingIsCancelled
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(state))];
}

#pragma mark - State

- (void)setState:(OPOperationState)newState
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(state))];

    switch (_state) {
        case OPOperationStateCancelled:
            break;
        case OPOperationStateFinished:
            break;
        default:
            NSAssert(_state != newState, @"Performing invalid cyclic state transition.");
            _state = newState;
    }

    [self didChangeValueForKey:NSStringFromSelector(@selector(state))];
}

- (void)evaluateConditions
{
    NSAssert(_state == OPOperationStatePending, @"evaluateConditions was called out-of-order");

    _state = OPOperationStateEvaluatingConditions;

    [OPOperationConditionEvaluator evaluateConditions:_conditions operation:self completion:^(NSArray *failures) {
        [self.internalErrors addObjectsFromArray:failures];
        self.state = OPOperationStateReady;
    }];
}

#pragma mark - NSOperation Overrides

- (BOOL)isReady
{
    switch (_state) {
        case OPOperationStatePending:
            if ([super isReady]) {
                [self evaluateConditions];
            }

            return NO;
        case OPOperationStateReady:
            return [super isReady];
        default:
            return NO;
    }
}

- (BOOL) userInitiated
{
    return self.qualityOfService == NSOperationQualityOfServiceUserInitiated;
}

- (void) setUserInitiated:(BOOL)userInitiated
{
    NSAssert(_state < OPOperationStateExecuting, @"Cannot modify userInitiated after execution has begun.");
    
    self.qualityOfService = userInitiated ? NSOperationQualityOfServiceUserInitiated : NSOperationQualityOfServiceUtility;
    
}

- (BOOL) isExecuting
{
    return _state == OPOperationStateExecuting;
}

- (BOOL) isFinished
{
    return _state == OPOperationStateFinished;
}

- (BOOL) isCancelled
{
    return _state == OPOperationStateCancelled;
}

#pragma mark - Conditions

- (void) addCondition:(id<OPOperationCondition>) condition
{
    NSAssert(_state < OPOperationStateEvaluatingConditions, @"Cannot modify conditions after execution has begun.");
    
    [_conditions addObject:condition];
}

#pragma mark - Observers

- (void) addObserver:(id<OPOperationObserver>)observer
{
    NSAssert(_state < OPOperationStateExecuting, @"Cannot modify observers after execution has begun.");
    
    [self.observers addObject:observer];
}


- (void) addDependency:(NSOperation *)operation
{
    NSAssert(_state <= OPOperationStateExecuting, @"Dependencies cannot be modified after execution has begun.");
    
    [super addDependency:operation];
}

#pragma mark - Execution and Cancellation

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
    NSAssert(_state == OPOperationStateReady, @"This operation must be performed on an operation queue.");

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

- (void) cancel
{
    self.state = OPOperationStateCancelled;
    [super cancel];
}

- (void) cancelWithError:(NSError *) error
{
    if (error)
    {
        [_internalErrors addObject:error];
    }

    [self cancel];
}

- (void) produceOperation:(NSOperation *) operation
{
    for (id<OPOperationObserver> observer in _observers)
    {
        [observer operation:self didProduceOperation:operation];
    }
}

#pragma mark - Finishing

- (void) finish;
{
    [self finishWithError:nil];
}

- (void) finishWithError:(NSError *) error
{
    if (error)
    {
        [self finishWithErrors:@[error]];
    }
    else
    {
        [self finishWithErrors:@[]];
    }
}

- (void) finishWithErrors:(NSArray *) errors
{
    if (!_hasFinishedAlready)
    {
        _hasFinishedAlready = YES;
        self.state = OPOperationStateFinishing;
        
        NSArray *combinedErrors = [_internalErrors arrayByAddingObjectsFromArray:errors];
        
        [self finishedWithErrors:combinedErrors];

        for (id <OPOperationObserver> observer in _observers) {
            [observer operation:self didFinishWithErrors:combinedErrors];
        }

        self.state = OPOperationStateFinished;
    }
}

- (void) finishedWithErrors:(NSArray *) errors
{
    // No op.
}

- (void) waitUntilFinished
{
    NSAssert(NO, @"I'm pretty sure you don't want to do this.");
}

@end
