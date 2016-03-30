// OPVideoCondition.m
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

@import AVFoundation;

#import "OPVideoCondition.h"
#import "OPMediaPermissionOperation.h"

#import "NSError+Operative.h"

@implementation OPVideoCondition

#pragma mark - OPOperationCondition Protocol
#pragma mark -

- (NSString *)name
{
    return @"Video";
}

- (BOOL)isMutuallyExclusive
{
    return NO;
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation
{
    return [[OPMediaPermissionOperation alloc] initWithMediaType:AVMediaTypeVideo];
}

- (void)evaluateConditionForOperation:(OPOperation *)operation completion:(void (^)(OPOperationConditionResultStatus, NSError *))completion
{
    NSArray *availableDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (status == AVAuthorizationStatusAuthorized || [availableDevices count] == 0) {
        completion(OPOperationConditionResultStatusSatisfied, nil);
    } else {
        NSDictionary *userInfo = @{ kOPOperationConditionKey : [self name] };
        NSError *error = [NSError errorWithCode:OPOperationErrorCodeConditionFailed userInfo:userInfo];
        completion(OPOperationConditionResultStatusFailed, error);
    }
}

@end
