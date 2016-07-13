// OPNegatedCondition.h
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

#import "OPOperationCondition.h"


NS_ASSUME_NONNULL_BEGIN


/**
 *  A simple condition that negates the evaluation of another condition.
 *  This is useful (for example) if you want to only execute an operation if the
 *  network is NOT reachable.
 */
@interface OPNegatedCondition : NSObject <OPOperationCondition>

/**
 *  Initializes an `OPNegatedCondition` object with the provided condition.
 *
 *  This is the designated initializer.
 *
 *  @param condition The condition which should be negated.
 *
 *  @return The newly-initialized `OPNegatedCondition`
 */
- (instancetype)initWithCondition:(id <OPOperationCondition>)condition NS_DESIGNATED_INITIALIZER;

/**
 *  Unused `-init` method.
 *  @see - initWithCondition:
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
