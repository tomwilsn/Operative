// OPOperationConditionMutuallyExclusive.h
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


@interface OPOperationConditionMutuallyExclusive : NSObject <OPOperationCondition>

+ (OPOperationConditionMutuallyExclusive *)mutuallyExclusiveWith:(Class)cls;

/**
 *  Class method that returns a mutually exclusive condition for a target
 *  operation that may present an alert.
 *
 *  @return `OPOperationConditionMutuallyExclusive` object with class of type
 *  `OPAlertPresentation`
 *
 *  @see OPAlertPresentation
 */
+ (OPOperationConditionMutuallyExclusive *)alertPresentationExclusivity;

- (instancetype)initWithClass:(Class)cls NS_DESIGNATED_INITIALIZER;

/**
 *  Unused `-init` method.
 *  @see -initWithClass:
 */
- (instancetype)init NS_UNAVAILABLE;

@end

/**
 *  Provides a simple class for usage in defining exclusivity for a target that
 *  may display an alert (via system, `UIAlertController`, `UIAlertView`, etc.)
 *
 *  When defining an operation with an alert view mutually exclusivity
 *  condition, always use this class as opposed to `[UIAlertController class]`
 *  or `[UIAlertView class]`.
 *
 *  For simplicity, `OPOperationConditionMutuallyExclusive` has a class method
 *  `+alertPresentationExclusivity` which returns a mutually exclusive condition
 *  setup with `[OPAlertPresentation class]`
 *
 *  @see alertPresentationExclusivity
 */
@interface OPAlertPresentation : NSObject
@end
