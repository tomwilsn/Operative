// OPPhotosCondition.m
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

@import Photos;

#import "OPPhotosCondition.h"
#import "OPOperationConditionMutuallyExclusive.h"

#import "NSError+Operative.h"


/**
 *  A private `OPOperation` that will request access to the user's Photos, if it
 *  has not already been granted.
 */
@interface OPPhotosPermissionOperation : OPOperation

@end


@implementation OPPhotosCondition


#pragma mark - OPOperationCondition Protocol
#pragma mark -

- (NSString *)name
{
    return @"Photos";
}

- (BOOL)isMutuallyExclusive
{
    return NO;
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation
{
    return [[OPPhotosPermissionOperation alloc] init];
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus, NSError *))completion
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusAuthorized) {
        completion(OPOperationConditionResultStatusSatisfied, nil);
    } else {
        NSDictionary *userInfo = @{ kOPOperationConditionKey : [self name] };
        NSError *error = [NSError errorWithCode:OPOperationErrorCodeConditionFailed userInfo:userInfo];
        completion(OPOperationConditionResultStatusFailed, error);
    }
}

@end


@implementation OPPhotosPermissionOperation


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self addCondition:[OPOperationConditionMutuallyExclusive alertPresentationExclusivity]];
    
    return self;
}


#pragma mark - Overrides
#pragma mark -

- (void)execute
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                [self finish];
            }];
        });
    } else {
        [self finish];
    }
}

@end
