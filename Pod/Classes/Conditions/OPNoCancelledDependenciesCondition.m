//
//  OPNoCancelledDependenciesCondition.m
//  Operative
//
//  Created by Andrej Mihajlov on 10/30/15.
//  Copyright © 2015 Tom Wilson. All rights reserved.
//

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
