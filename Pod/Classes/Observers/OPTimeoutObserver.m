// OPTimeoutObserver.m
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

#import "OPTimeoutObserver.h"
#import "OPOperation.h"
#import "NSError+Operative.h"


static NSString *const kOPTimeoutObserverErrorKey = @"OPTimeoutObserverError";


@interface OPTimeoutObserver ()

@property (assign, nonatomic) NSTimeInterval timeout;

#if OS_OBJECT_USE_OBJC
@property (strong, nonatomic) dispatch_source_t timer;
#else
@property (assign, nonatomic) dispatch_source_t timer;
#endif

@end


@implementation OPTimeoutObserver

#pragma mark - OPOperationObserver Protocol
#pragma mark -

- (void)operationDidStart:(OPOperation *)operation
{
    // set up timeout handler
    void(^timeoutHandler)() = ^{
        /**
         *  Cancel the operation if it hasn't finished and hasn't already
         *  been cancelled.
         */
        if (![operation isFinished] && ![operation isCancelled]) {
            NSDictionary *userInfo = @{ kOPTimeoutObserverErrorKey : @(([self timeout])) };
            NSError *error = [NSError errorWithCode:OPOperationErrorCodeExecutionFailed userInfo:userInfo];
            [operation cancelWithError:error];
        }
    };
    
    // When the operation starts, queue up a block to cause it to time out.
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0));
    
    // Cancel operation immediately if timer wasn't created
    if(!self.timer) {
        timeoutHandler();
        return;
    }
    
    // calculate time delta
    int64_t delta = (int64_t)(self.timeout * NSEC_PER_SEC);
    
    // calculate the leeway for timer using the same way as dispatch_after
    int64_t leeway = delta / 10;
    if(leeway < NSEC_PER_MSEC) leeway = NSEC_PER_MSEC;
    if(leeway > 60 * NSEC_PER_SEC) leeway = 60 * NSEC_PER_SEC;
    
    dispatch_time_t when = dispatch_walltime(NULL, delta);
    dispatch_source_set_event_handler(self.timer, timeoutHandler);
    dispatch_source_set_timer(self.timer, when, DISPATCH_TIME_FOREVER, leeway);
    dispatch_resume(self.timer);
}

- (void)operation:(OPOperation *)operation didProduceOperation:(NSOperation *)newOperation
{
    // No-op
}

- (void)operation:(OPOperation *)operation didFinishWithErrors:(NSArray *)errors
{
    if(!self.timer) {
        return;
    }
    
    // Cancel and release the timer
    dispatch_source_cancel(self.timer);
    
#if !OS_OBJECT_USE_OBJC
    dispatch_release(self.timer);
#endif
    
    self.timer = nil;
}


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)initWithTimeout:(NSTimeInterval)timeout;
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _timeout = timeout;

    return self;
}

@end
