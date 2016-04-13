// OPOperation.h
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

#import <Foundation/Foundation.h>

@protocol OPOperationObserver;
@protocol OPOperationCondition;


/**
 *  `OPOperation` is a subclass of `NSOperation`
 *  from which all other operations within `Operative` should be derived.
 *  This class adds both Conditions and Observers, which allow the operation
 *  to define extended readiness requirements, as well as notify many
 *  interested parties about interesting operation state changes
 */
@interface OPOperation : NSOperation

/**
 *  `BOOL` value indicating if the operation is considered user
 *  initiated. Changing this value will change the operations quality
 *  of service to `NSOperationQualityOfServiceUserInitiated` or
 *  `NSOperationQualityOfServiceUtility` accordingly
 */
@property (assign, nonatomic) BOOL userInitiated;

/**
 *  An array of objects that conform to the `OPOperationCondition`
 *  protocol. Before execution of the operation, conditions will be
 *  checked and if met the operation will execute as normal.
 *
 *  Array should not be manipulated directly.
 *
 *  @see -addCondition:
 */
@property (strong, nonatomic, readonly) NSMutableArray *conditions;


///---------------------------------------------
/// @name Conditions, Observers and Dependencies
///---------------------------------------------

- (void)addCondition:(id <OPOperationCondition>)condition;

- (void)addObserver:(id <OPOperationObserver>)observer;

- (void)addDependency:(NSOperation *)operation;

/**
 *  Returns condition evaluation operation used by OPOperationQueue.
 */
- (NSOperation *)conditionEvaluationOperation;


///---------------------------------
/// @name Execution and Cancellation
///---------------------------------

/**
 *  Indicates that the Operation can now begin to evaluate
 *  readiness conditions, if appropriate.
 */
- (void)willEnqueue;

/**
 *  -execute is the entry point of execution for all `OPOperation` subclasses.
 *  If you subclass `OPOperation` and wish to customize its execution, you
 *  would do so by overriding the -execute method.
 *  At some point, your `OPOperation` subclass must call one of the "finish"
 *  methods defined below; this is how you indicate that your operation has
 *  finished its execution, and that operations dependent on yours can
 *  re-evaluate their readiness state.
 */
- (void)execute;

- (void)cancelWithError:(NSError *)error;

- (void)produceOperation:(NSOperation *)operation;

/*
 *  This is a convenience method to simplify calling the actual
 *  -finishWithErrors: method, when an error isn't present
 *
 *  @see -finishWithError:
 */
- (void)finish;

/*
 *  Most operations may finish with a single error, if they have one at all.
 *  This is a convenience method to simplify the calling of -finishWithErrors:
 *  -finishWithError: is useful if you wish to finish with an error provided
 *  by the system frameworks / when a single error is present.
 *
 *  @see -finish
 *  @see -finishWithErrors:
 */
- (void)finishWithError:(NSError *)error;

/*
 *  Called once an `OPOperation` has finished. This method transitions the
 *  operation to a state of finishing, informs any observers that the operation
 *  finished, and then transitions to a state of finished
 *
 *  @see -finish
 *  @see -finishWithError:
 */
- (void)finishWithErrors:(NSArray *)errors;

/*
 *  Subclasses may override -finishedWithErrors: if they wish to react to the operation
 *  finishing with errors.
 */
- (void)finishedWithErrors:(NSArray *)errors;

@end
