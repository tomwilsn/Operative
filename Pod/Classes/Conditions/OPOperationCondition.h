// OPOperationCondition.h
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
 *  An enum to indicate whether an `OPOperationCondition` was satisfied,
 *  or if it failed with an error.
 */
typedef NS_ENUM(NSUInteger, OPOperationConditionResultStatus){
    // Operation condition was satisfied
    OPOperationConditionResultStatusSatisfied,
    // Operation condition failed
    OPOperationConditionResultStatusFailed,
};


/**
 *  A protocol for defining conditions that must be satisfied in order for an
 *  operation to begin execution.
 */
@protocol OPOperationCondition <NSObject>

/**
 *  The name of the condition. This is used in userInfo dictionaries of
 *  `OPOperationConditionResultStatusFailed` errors as the value of the
 *  `OPOperationConditionKey` key.
 */
@property (strong, nonatomic, readonly) NSString *name;

/**
 *  Specifies whether multiple instances of the conditionalized operation may
 *  be executing simultaneously.
 */
@property (assign, nonatomic, readonly) BOOL isMutuallyExclusive;

/**
 *  Some conditions may have the ability to satisfy the condition if another
 *  operation is executed first. Use this method to return an operation that
 *  (for example) asks for permission to perform the operation.
 *
 *  @param operation: The `OPOperation` to which the Condition has been added.
 *
 *  @return An `NSOperation`, if a dependency should be automatically added.
 *  Otherwise, `nil`.
 *
 *  @note Only a single operation may be returned as a dependency. If you
 *  find that you need to return multiple operations, then you should be
 *  expressing that as multiple conditions. Alternatively, you could return
 *  a single `OPGroupOperation` that executes multiple operations internally.
 */
- (NSOperation *)dependencyForOperation:(OPOperation *)operation;

/**
 *  Evaluate the condition, to see if it has been satisfied or not.
 *
 *  TODO:// Get these params doc'd correctly
 *  @param operation  -
 *  @param completion -
 */
- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus result, NSError *error))completion;

@end

