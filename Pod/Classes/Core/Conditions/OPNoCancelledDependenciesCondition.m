// OPNoCancelledDependenciesCondition.m
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

#import "OPNoCancelledDependenciesCondition.h"
#import "NSError+Operative.h"

NSString * const kOPCancelledDependenciesKey = @"CancelledDependencies";

@implementation OPNoCancelledDependenciesCondition

- (BOOL)isMutuallyExclusive {
    return NO;
}

- (NSString *)name {
    return @"NoCancelledDependencies";
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation {
    return nil;
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus result, NSError *error))completion
{
    // Verify that all of the dependencies executed.
    NSArray *cancelled = [operation.dependencies filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"cancelled = YES"]];
    
    // Satisfied until not
    OPOperationConditionResultStatus resultStatus = OPOperationConditionResultStatusSatisfied;
    
    NSError *error;
    
    if(cancelled.count != 0) {
        // At least one dependency was cancelled; the condition was not satisfied.
        NSDictionary *userInfo = @{
            kOPOperationConditionKey: NSStringFromClass([self class]),
            kOPCancelledDependenciesKey: cancelled
        };
        
        error = [NSError errorWithCode:OPOperationErrorCodeConditionFailed userInfo:userInfo];
        resultStatus = OPOperationConditionResultStatusFailed;
    }
    
    completion(resultStatus, error);
}

@end
