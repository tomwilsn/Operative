// OPRemoteNotificationCondition.m
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

#import "OPRemoteNotificationCondition.h"
#import "OPOperationQueue.h"
#import "OPOperationConditionMutuallyExclusive.h"

#import "NSError+Operative.h"


static NSString *const kOPRemoteNotificationName = @"RemoteNotificationPermissionNotification";
static NSString *const kOPRemoteNotificationOperationTokenKey = @"RemoteNotificationOperationToken";
static NSString *const kOPRemoteNotificationOperationErrorKey = @"RemoteNotificationOperationError";


/**
 *  A private `OPOperation` to request a push notification token from the `UIApplication`.
 *
 *  - note: This operation is used for *both* the generated dependency **and**
 *  condition evaluation, since there is no "easy" way to retrieve the push
 *  notification token other than to ask for it.
 *
 *  - note: This operation requires you to call either
 *  `[OPRemoteNotificationCondition didReceiveNotificationToken:]` or
 *  `[OPRemoteNotificationCondition didFailToRegister:]` in the appropriate
 *  `UIApplicationDelegate` method
 */
@interface OPRemoteNotificationPermissionOperation : OPOperation

@property (strong, nonatomic, readonly) UIApplication *application;

@property (copy, nonatomic, readonly) void (^handler)(NSData *token, NSError *error);

- (instancetype)initWithApplication:(UIApplication *)application
                  completionHandler:(void (^)(NSData *token, NSError *error))handler;

@end


@interface OPRemoteNotificationCondition ()

@property (strong, nonatomic, readonly) UIApplication *application;

@property (strong, nonatomic) OPOperationQueue *remoteNotificationQueue;

@end

@implementation OPRemoteNotificationCondition


#pragma mark - Class Methods
#pragma mark -

+ (void)didReceiveNotificationToken:(NSData *)token
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kOPRemoteNotificationName object:nil userInfo:@{
        kOPRemoteNotificationOperationTokenKey : token
    }];
}

+ (void)didFailToRegister:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kOPRemoteNotificationName object:nil userInfo:@{
        kOPRemoteNotificationOperationErrorKey : error
    }];
}

#pragma mark - OPOperationCondition Protocol
#pragma mark -

- (NSString *)name
{
    return @"RemoteNotification";
}

- (BOOL)isMutuallyExclusive
{
    return NO;
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation
{
    return [[OPRemoteNotificationPermissionOperation alloc] initWithApplication:[self application]
                                                              completionHandler:^(NSData *token, NSError *error) {}];
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus, NSError *))completion
{
    // Since evaluation requires executing an operation, use a private operation
    // queue.
    OPRemoteNotificationPermissionOperation *permissionOperation;
    permissionOperation = [[OPRemoteNotificationPermissionOperation alloc] initWithApplication:[self application]
                                                                             completionHandler:^(NSData *token, NSError *underlyingError) {
                                                                                 if (underlyingError) {
                                                                                     NSDictionary *userInfo = @{
                                                                                         kOPOperationConditionKey : [self name],
                                                                                         NSUnderlyingErrorKey : underlyingError
                                                                                     };
                                                                                     NSError *error = [NSError errorWithCode:OPOperationErrorCodeConditionFailed
                                                                                                                    userInfo:userInfo];

                                                                                     completion(OPOperationConditionResultStatusFailed, error);
                                                                                 } else {
                                                                                     completion(OPOperationConditionResultStatusSatisfied, nil);
                                                                                 }
                                                                             }];
    [self.remoteNotificationQueue addOperation:permissionOperation];
}

#pragma mark - Lifecycle
#pragma mark -

- (instancetype)initWithApplication:(UIApplication *)application
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _application = application;
    _remoteNotificationQueue = [[OPOperationQueue alloc] init];

    return self;
}

@end


#pragma mark - Remote Notification Permission Operation
#pragma mark -

@implementation OPRemoteNotificationPermissionOperation


#pragma mark - Actions
#pragma mark -

- (void)didReceiveRemoteRegistrationResponse:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    NSDictionary *userInfo = [notification userInfo];

    if (userInfo[kOPRemoteNotificationOperationTokenKey]) {
        self.handler(userInfo[kOPRemoteNotificationOperationTokenKey], nil);
    } else if (userInfo[kOPRemoteNotificationOperationErrorKey]) {
        self.handler(nil, userInfo[kOPRemoteNotificationOperationErrorKey]);
    } else {
        NSAssert(
            userInfo[kOPRemoteNotificationOperationTokenKey] ||
            userInfo[kOPRemoteNotificationOperationErrorKey],
            @"Received a notification without a token and without an error."
        );
    }
    
    [self finish];
}


#pragma mark - Override
#pragma mark -

- (void)execute
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didReceiveRemoteRegistrationResponse:) name:kOPRemoteNotificationName object:nil];

        [self.application registerForRemoteNotifications];
    });
}


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)initWithApplication:(UIApplication *)application
                  completionHandler:(void (^)(NSData *token, NSError *error))handler
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _application = application;
    _handler = [handler copy];

    // This operation cannot run at the same time as any other remote notification
    // permission operation.
    OPOperationConditionMutuallyExclusive *condition;
    Class cls = [self class];
    condition = [[OPOperationConditionMutuallyExclusive alloc] initWithClass:cls];

    [self addCondition:condition];
    
    return self;
}

@end
