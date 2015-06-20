// OPURLSessionOperation.m
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


#import "OPURLSessionOperation.h"

@interface OPURLSessionOperation()

@property (strong, nonatomic) NSURLSessionTask *task;
@property (assign, nonatomic) unsigned long kvoContext;
@end

@implementation OPURLSessionOperation


- (instancetype) initWithTask:(NSURLSessionTask *) task
{
    self = [super init];
    if (self)
    {
        NSAssert(task.state == NSURLSessionTaskStateSuspended, @"Tasks must be suspended.");
        self.task = task;
    }
    return self;
}

- (void) execute
{
    NSAssert(self.task.state == NSURLSessionTaskStateSuspended, @"Task was resumed by something other than %@", self);
    
    [self.task addObserver:self forKeyPath:@"state" options:0 context:&_kvoContext];
    [self.task resume];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &_kvoContext)
    {
        [self.task removeObserver:self forKeyPath:@"state"];
        [self finish];
    }
}

- (void) cancel
{
    [self.task cancel];
    [super cancel];
}

@end
