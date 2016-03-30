// OPBlockOperation.h
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
 *  An operation block that takes a block as it's parameter
 *
 *  @param ^completion: Block to be executed upon completion of an
 *  `OPBlockOperation`
 */
typedef void (^OPOperationBlock)(void (^completion)(void));


/**
 *  A subclass of `OPOperation` to execute a block.
 *  - returns: An instance of an `OPBlockOperation`
 */
@interface OPBlockOperation : OPOperation

/**
 *  Designated Initialized for `OPBlockOperation`
 *
 *  @param block: The block to run when the operation executes. This
 *  block will be run on an arbitrary queue. The parameter passed to the
 *  block **MUST** be invoked by your code, or else the `OPBlockOperation`
 *  will never finish executing. If this parameter is `nil`, the operation
 *  will immediately finish.
 *
 *  @return An instance of an `OPBlockOperation`
 */
- (instancetype)initWithBlock:(OPOperationBlock)block NS_DESIGNATED_INITIALIZER;

/**
 *  A convenience initializer to execute a block on the main queue.
 *
 *  @param mainQueueBlock: The block to execute on the main queue. Note
 *  that this block does not have a "continuation" block to execute (unlike
 *  the designated initializer). The operation will be automatically ended
 *  after the `mainQueueBlock` is executed.
 *
 *  @return An instance of an `OPBlockOperation` that will run on the main queue
 */
- (instancetype)initWithMainQueueBlock:(void (^)(void))mainQueueBlock;

/**
 *  Unused `-init` method.
 *  @see -initWithBlock:
 *  @see -initWithMainQueueBlock:
 */
- (instancetype)init NS_UNAVAILABLE;

@end
