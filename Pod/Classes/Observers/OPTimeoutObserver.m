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

NSString * const kTimeoutKey = @"Timeout";

@interface OPTimeoutObserver()

@property (assign, nonatomic) NSTimeInterval timeout;

@end

@implementation OPTimeoutObserver

- (instancetype) initWithTimeout:(NSTimeInterval) timeout;
{
    self = [super init];
    if (self)
    {
        _timeout = timeout;
    }
    return self;
}

- (void) operationDidStart:(OPOperation *)operation
{
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, _timeout * NSEC_PER_SEC);
    
    dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        if (!operation.isFinished && !operation.isCancelled)
        {
            NSError *error = [NSError errorWithCode:OPOperationErrorCodeExecutionFailed userInfo:@{
                                                                                                   kTimeoutKey: @(self.timeout)
                                                                                                   }];
            [operation cancelWithError:error];
        }
    });
}

- (void) operation:(OPOperation *)operation didProduceOperation:(NSOperation *)newOperation
{
}

- (void) operation:(OPOperation *)operation didFinishWithErrors:(NSArray *)errors
{
}

@end
