// OPSilentCondition.m
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


#import "OPSilentCondition.h"


@interface OPSilentCondition ()

/**
 *  Underlying condition which is evaluated.
 */
@property (strong, nonatomic, readonly) id <OPOperationCondition> condition;

/**
 *  Unused `-init` method. Do not used, will throw an exception.
 *
 *  @return Nothing returned, throws an exception if used.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER; // Silences compiler crankiness

@end


@implementation OPSilentCondition


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)initWithCondition:(id <OPOperationCondition>)condition
{
    self = [super init];

    _condition = condition;

    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"%@ not implemented, use -initWithCondition: instead", NSStringFromSelector(_cmd)]
                                 userInfo:@{ @"file": @(__FILE__), @"line": @(__LINE__) }];
    return nil;
}


#pragma mark - OPOperationCondition Protocol
#pragma mark -

- (NSString *)name
{
    return [NSString stringWithFormat:@"Silent<%@>", [self.condition name]];
}

- (BOOL)isMutuallyExclusive
{
    return [self.condition isMutuallyExclusive];
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation
{
    return nil;
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus result, NSError *error))completion
{
    [self.condition evaluateConditionForOperation:operation
                                       completion:completion];
}


@end
