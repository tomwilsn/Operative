// OPLocationCondition.h
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


typedef NS_ENUM(NSUInteger, OPLocationConditionUsage) {
    OPLocationConditionWhenInUse,
    OPLocationConditionAlways,
};


/**
 *  A condition for verifying access to the user's location.
 *
 *  - returns: An `NSObject` conforming to the `OPOperationCondition` protocol
 */
@interface OPLocationCondition : NSObject <OPOperationCondition>

/**
 *  Designated initializer, otherwise calling `-init` will return an
 *  `OPLocationCondition` with a default usage of
 *  `OPLocationConditionWhenInUse`.
 *
 *  @param usage A value defining the required location usage permission in
 *               order to satisfy the condition.
 *
 *  @return An `OPLocationCondition` object with the required location usage
 *          permission defined.
 */
- (instancetype)initWithUsage:(OPLocationConditionUsage)usage NS_DESIGNATED_INITIALIZER;

@end
