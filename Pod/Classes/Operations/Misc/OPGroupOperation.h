// OPGroupOperation.h
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


/**
 *  A subclass of `OPOperation` that executes zero or more operations as part
 *  of its own execution. This class of operation is very useful for abstracting
 *  several smaller operations into a larger operation.
 *
 *  Additionally, `OPGroupOperation`s are useful if you establish a chain of
 *  dependencies, but part of the chain may "loop". For example, if you have an
 *  operation that requires the user to be authenticated, you may consider
 *  putting the "login" operation inside a group operation. That way,
 *  the "login" operation may produce subsequent operations
 *  (still within the outer `OPGroupOperation`) that will all be executed before
 *  the rest of the operations in the initial chain of operations.
 *
 *  - returns: An instance of `OPGroupOperation
 */
@interface OPGroupOperation : OPOperation

/**
 *  Initializes an `OPGroupOperation` object and adds the provided operations to
 *  its internal queue
 *
 *  @param operations An `NSArray` of operations to be group together into a
 *                    single executable operation.
 *
 *  @return An `OPGroupOperation` object
 */
- (instancetype)initWithOperations:(NSArray *)operations NS_DESIGNATED_INITIALIZER;

/**
 *  Adds an operation to the group after instantiation
 *
 *  @param operation Operation to add to the group
 */
- (void)addOperation:(NSOperation *)operation;

/**
 *  Note that some part of execution has produced an error.
 *  Errors aggregated through this method will be included in the final array
 *  of errors reported to observers and to the `-finished:` method.
 *
 *  @param error `NSError` to be aggregated
 */
- (void)aggregateError:(NSError *)error;

/**
 *  Method called upon finish of an operation within the group
 *  To be overriden by subclass of `OPGroupOperation`.
 *
 *  @param operation Operation that did finish.
 *  @param errors    Array of `NSErrors` during execution of operation or nil.
 */
- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors;

@end
