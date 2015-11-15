// OPURLSessionOperation.h
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
 *  `OPURLSessionTaskOperation` is an `OPOperation` that lifts an `NSURLSessionTask`
 *  into an operation.
 *
 *  Note that this operation does not participate in any of the delegate callbacks
 *  of an `NSURLSession`, but instead uses Key-Value-Observing to know when the
 *  task has been completed. By default the operation gets notified of errors that occur during
 *  execution of the task. Upon completion, if the task has produced an error,
 *  `-finishWithError:` will receive this error and the operation will accrue the error
 *  from the task as an internal error.
 *
 *  As an option, one can set the value of `shouldSuppressErrors` to YES
 *  and the operation will not get notified about any errors that occurred during
 *  execution of the task.
 *
 *  @see shouldSuppressErrors
 *
 *  - returns: An instance of an `OPURLSessionTaskOperation`
 */
@interface OPURLSessionTaskOperation : OPOperation

- (instancetype)initWithTask:(NSURLSessionTask *)task NS_DESIGNATED_INITIALIZER;

/**
 *  Evaluated upon completion of the provided `NSURLSessionTask`, this value
 *  dictates how errors occurring during the execution of the task are handled.
 *
 *  If set to YES, completion of the task will not pass along any errors that
 *  may have occurred during execution to the operation via -finishedWithError:.
 *
 *  Defaults to NO
 */
@property (assign, nonatomic) BOOL shouldSuppressErrors;

/**
 *  Unused `-init` method.
 *  @see -initWithTask:
 */
- (instancetype)init NS_UNAVAILABLE;

@end
