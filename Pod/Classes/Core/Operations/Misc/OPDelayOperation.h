// OPDelayOperation.h
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
 *  `OPDelayOperation` is an `OPOperation` that will simply wait for a given time
 *  interval, or until a specific `NSDate`.
 *
 *  It is important to note that this operation does **not** use the `sleep()`
 *  function, since that is inefficient and blocks the thread on which it is called.
 *  Instead, this operation uses `dispatch_after` to know when the appropriate amount
 *  of time has passed.
 *
 *  If the interval is negative, or the `NSDate` is in the past, then this operation
 *  immediately finishes.
 *
 *  - returns: An instance of an `OPDelayOperation`
 */
@interface OPDelayOperation : OPOperation

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithDate:(NSDate *)date;

/**
 *  Unused `-init` method.
 *  @see -initWithTimeInterval:
 *  @see -initWithDate:
 */
- (instancetype)init NS_UNAVAILABLE;

@end
