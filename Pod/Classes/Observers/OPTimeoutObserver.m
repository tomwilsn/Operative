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

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end


@implementation OPTimeoutObserver

#pragma mark - OPOperationObserver Protocol
#pragma mark -

- (void)operationDidStart:(OPOperation *)operation
{
    // When the operation starts, queue up a block to cause it to time out.
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)([self timeout] * NSEC_PER_SEC));

    dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        /**
         *  Cancel the operation if it hasn't finished and hasn't already
         *  been cancelled.
         */
        if (![operation isFinished] && ![operation isCancelled]) {
            NSDictionary *userInfo = @{ kOPTimeoutObserverErrorKey : @(([self timeout])) };
            NSError *error = [NSError errorWithCode:OPOperationErrorCodeExecutionFailed userInfo:userInfo];
            [operation cancelWithError:error];
        }
    });
}

- (void)operation:(OPOperation *)operation didProduceOperation:(NSOperation *)newOperation
{
    // No-op
}

- (void)operation:(OPOperation *)operation didFinishWithErrors:(NSArray *)errors
{
    // No-op
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

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    return self;
}

@end
