// OPBackgroundObserver.m
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


#import "OPBackgroundObserver.h"


@interface OPBackgroundObserver ()

@property (assign, nonatomic) UIBackgroundTaskIdentifier identifier;

@property (assign, nonatomic, getter=isInBackground) BOOL inBackground;


@end


@implementation OPBackgroundObserver


#pragma mark - Start / End Background Task
#pragma mark -

- (void)startBackgroundTask
{
    if ([self identifier] != UIBackgroundTaskInvalid) {
        return;
    }

    UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:NSStringFromClass([OPBackgroundObserver class])
                                                                                         expirationHandler:^{
                                                                                             [self endBackgroundTask];
                                                                                         }];
    [self setIdentifier:identifier];
}

- (void)endBackgroundTask
{
    if ([self identifier] == UIBackgroundTaskInvalid) {
        return;
    }

    [[UIApplication sharedApplication] endBackgroundTask:[self identifier]];
    [self setIdentifier:UIBackgroundTaskInvalid];
}


#pragma mark - Notification Actions
#pragma mark -

- (void)didEnterBackground:(NSNotification *)notification
{
    if (![self isInBackground]) {
        [self setInBackground:YES];
        [self startBackgroundTask];
    }
}

- (void)didEnterForeground:(NSNotification *)notification
{
    if ([self isInBackground]) {
        [self setInBackground:NO];
        [self endBackgroundTask];
    }
}


#pragma mark - OPOperationObserver Protocol
#pragma mark -

- (void)operationDidStart:(OPOperation *)operation
{
    // No-op
}

- (void)operation:(OPOperation *)operation didProduceOperation:(NSOperation *)newOperation
{
    // No-op
}

- (void)operation:(OPOperation *)operation didFinishWithErrors:(NSArray *)errors
{
    [self endBackgroundTask];
}


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }

    // We need to know when the application moves to/from the background.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(didEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];

    _identifier = UIBackgroundTaskInvalid;
    _inBackground = ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground);

    // If we're in the background already, immediately begin the background task.
    if (_inBackground) {
        [self startBackgroundTask];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
