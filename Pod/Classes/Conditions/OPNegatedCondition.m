// OPNegatedCondition.m
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

#import "OPNegatedCondition.h"
#import "NSError+Operative.h"


@interface OPNegatedCondition ()

/**
 *  Underlying condition which is evaluated.
 */
@property (strong, nonatomic, readonly) id <OPOperationCondition> condition;

@end


@implementation OPNegatedCondition


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)initWithCondition:(id <OPOperationCondition>)condition
{
    self = [super init];

    _condition = condition;

    return self;
}


#pragma mark - OPOperationCondition Protocol
#pragma mark -

- (NSString *)name
{
    return [NSString stringWithFormat:@"Not<%@>", [self.condition name]];
}

- (BOOL)isMutuallyExclusive
{
    return [self.condition isMutuallyExclusive];
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation
{
    return [self.condition dependencyForOperation:operation];
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(__unused OPOperationConditionResultStatus aResult, __unused NSError *anError))completion
{
    void (^underlyingCompletion)(OPOperationConditionResultStatus, NSError *) = ^(OPOperationConditionResultStatus result, __unused NSError *error) {
        switch (result) {
            case OPOperationConditionResultStatusSatisfied: {
                // If the composed condition succeeded, then this one failed.
                NSDictionary *userInfo = @{
                    kOPOperationConditionKey : NSStringFromClass([self class]),
                    kOPOperationNegatedConditionKey : NSStringFromClass([self.condition class])
                };
                NSError *negatedError = [NSError errorWithCode:OPOperationErrorCodeConditionFailed userInfo:userInfo];
                completion(OPOperationConditionResultStatusFailed, negatedError);
            }
                break;

            case OPOperationConditionResultStatusFailed: {
                // If the composed condition failed, then this one succeeded.
                completion(OPOperationConditionResultStatusSatisfied, nil);
            }
                break;

            default:
                break;
        }
    };

    [self.condition evaluateConditionForOperation:operation
                                       completion:underlyingCompletion];
}


@end