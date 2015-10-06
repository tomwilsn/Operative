// OPOperationQueue.h
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


@class OPOperationQueue;


/**
 *  The delegate of an `OPOperationQueue` can respond to `OPOperation` lifecycle
 *  events by implementing these methods.
 *
 *  In general, implementing `OPOperationQueueDelegate` is not necessary;
 *  you would want to use an `OPOperationObserver` instead.
 *  However, there are a couple of situations where using
 *  `OPOperationQueueDelegate` can lead to simpler code.
 *  For example, `OPGroupOperation` is the delegate of its own internal
 *  `OPOperationQueue` and uses it to manage dependencies.
 */
@protocol OPOperationQueueDelegate <NSObject>

@optional

- (void)operationQueue:(OPOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation;

- (void)operationQueue:(OPOperationQueue *)operationQueue operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors;

@end


/**
 *  `OPOperationQueue` is an `NSOperationQueue` subclass that implements a large
 *  number of "extra features" related to the `OPOperation` class:
 *
 *  - Notifying a delegate of all operation completion
 *  - Extracting generated dependencies from operation conditions
 *  - Setting up dependencies to enforce mutual exclusivity
 */
@interface OPOperationQueue : NSOperationQueue

@property (weak, nonatomic) id <OPOperationQueueDelegate>delegate;

- (void)addOperation:(NSOperation *)operation;

- (void)addOperations:(NSArray *)operations waitUntilFinished:(BOOL)wait;

@end
