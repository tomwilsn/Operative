// OPDelayOperation.m
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

#import "OPDelayOperation.h"

@interface OPDelayOperation()

@property (assign, nonatomic) NSTimeInterval delay;

@end

@implementation OPDelayOperation


- (instancetype) initWithDate:(NSDate *) date
{
    return [self initWithTimeInterval:[date timeIntervalSinceNow]];
}

- (instancetype) initWithTimeInterval:(NSTimeInterval) interval
{
    self = [super init];
    if (self)
    {
        _delay = interval;
    }
    return self;
}

- (void) execute
{
    if (self.delay < 0)
    {
        [self finish];
        return;
    }
    
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, self.delay * NSEC_PER_SEC);
    
    dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        if (self.isExecuting)
        {
            [self finish];
        }
    });
}

- (void) cancel
{
    [self finish]; // cancelling a delay just removes the delay :-)
}

@end
