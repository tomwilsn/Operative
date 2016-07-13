// OPOperationConditionEvaluator.m
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

#import "OPOperationConditionEvaluator.h"
#import "OPOperationCondition.h"
#import "NSError+Operative.h"


@implementation OPOperationConditionEvaluator

+ (void)evaluateConditions:(NSArray *)conditions
                 operation:(OPOperation *)operation
                completion:(void (^)(NSArray *failures))completion;
{
    // Check conditions.
    dispatch_group_t conditionGroup = dispatch_group_create();

    NSMutableArray *results = [[NSMutableArray alloc] init];
    [conditions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [results addObject:[NSNull null]];
    }];

    // Ask each condition to evaluate and store its result in the "results" array.
    [conditions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id <OPOperationCondition>condition = obj;

        dispatch_group_enter(conditionGroup);
        [condition evaluateConditionForOperation:operation completion:^(OPOperationConditionResultStatus result, NSError *error) {
            if (error) {
                results[idx] = error;
            }
            dispatch_group_leave(conditionGroup);
        }];
    }];

    // After all the conditions have evaluated, this block will execute
    dispatch_group_notify(conditionGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        // Aggregate the errors that occurred, in order.
        NSMutableArray *failures = [[NSMutableArray alloc] init];
        [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[NSError class]]) {
                [failures addObject:obj];
            }
        }];

        // If any of the conditions caused this operation to be cancelled, check for that
        if ([operation isCancelled]) {
            [failures addObject:[NSError errorWithCode:OPOperationErrorCodeConditionFailed]];
        }

        completion(failures);
    });
}

@end
