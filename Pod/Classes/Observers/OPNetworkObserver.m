// OPNetworkObserver.m
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

#import "OPNetworkObserver.h"


/**
 *  Essentially a cancellable `dispatch_after`.
 */
@interface OPTimer : NSObject

@property (assign, nonatomic, getter=isCancelled) BOOL cancelled;

@property (copy, nonatomic, readonly) dispatch_block_t handler;

- (instancetype)initWithInterval:(NSTimeInterval)interval handler:(dispatch_block_t)handler NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (void)cancel;

@end


/**
 *  A singleton to manage a visual "reference count" on the network activity indicator.
 */
@interface OPNetworkIndicatorController : NSObject

+ (OPNetworkIndicatorController *)sharedInstance;

@property (assign, nonatomic) NSUInteger activityCount;

@property (strong, nonatomic) OPTimer *visibilityTimer;

- (void)networkActivityDidStart;

- (void)networkActivityDidEnd;

- (void)updateIndicatorVisibility;

@end


@implementation OPNetworkObserver

- (void)operationDidStart:(OPOperation *)operation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Increment the network indicator's "reference count"
        [[OPNetworkIndicatorController sharedInstance] networkActivityDidStart];
    });
}

- (void)operation:(OPOperation *)operation didProduceOperation:(NSOperation *)newOperation {}

- (void)operation:(OPOperation *)operation didFinishWithErrors:(NSArray *)errors
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Decrement the network indicator's "reference count".
        [[OPNetworkIndicatorController sharedInstance] networkActivityDidEnd];
    });
}

@end


@implementation OPNetworkIndicatorController

+ (OPNetworkIndicatorController *)sharedInstance
{
    static OPNetworkIndicatorController *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OPNetworkIndicatorController alloc] init];
    });

    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _activityCount = 0;

    return self;
}

- (void)networkActivityDidStart
{
    NSAssert([NSThread isMainThread], @"Altering network activity indicator state can only be done on the main thread.");
    self.activityCount++;

    [self updateIndicatorVisibility];
}

- (void)networkActivityDidEnd
{
    self.activityCount--;

    [self updateIndicatorVisibility];
}

- (void)updateIndicatorVisibility
{
    if ([self activityCount] > 0) {
        [self showIndicator];
    } else {
        /*
            To prevent the indicator from flickering on and off, we delay the
            hiding of the indicator by one second. This provides the chance
            to come in and invalidate the timer before it fires.
        */
        OPTimer *timer = [[OPTimer alloc] initWithInterval:1.0f
                                                   handler:^{
                                                       [self hideIndicator];
                                                   }];
        [self setVisibilityTimer:timer];
    }
}

- (void)cancelVisibilityTimer
{
    if ([self visibilityTimer]) {
        [self.visibilityTimer cancel];
        [self setVisibilityTimer:nil];
    }
}

- (void)showIndicator
{
    [self cancelVisibilityTimer];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)hideIndicator
{
    [self cancelVisibilityTimer];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end


@implementation OPTimer

#pragma mark - Public
#pragma mark -

- (void)cancel
{
    [self setCancelled:YES];
}

- (void)fire
{
    if (![self isCancelled]) {
        self.handler();
    }
}


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)initWithInterval:(NSTimeInterval)interval
                         handler:(dispatch_block_t)handler
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _handler = [handler copy];

    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));

    __weak __typeof__(self) weakSelf = self;
    dispatch_after(when, dispatch_get_main_queue(), ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf fire];
    });

    return self;
}

@end
