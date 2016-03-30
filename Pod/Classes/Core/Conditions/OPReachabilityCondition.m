// OPReachabilityCondition.m
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

#import "OPReachabilityCondition.h"

#import "NSError+Operative.h"

#import <SystemConfiguration/SystemConfiguration.h>


static NSString *const kOPOperationHostKey = @"OperationHost";


@interface OPReachabilityController : NSObject

+ (OPReachabilityController *)sharedInstance;

#if OS_OBJECT_USE_OBJC
@property (strong, nonatomic) dispatch_queue_t reachabilityQueue;
#else
@property (assign, nonatomic) dispatch_queue_t reachabilityQueue;
#endif

@property (strong, nonatomic) NSMutableDictionary *reachabilityRefs;

- (void)requestReachabilityWithURL:(NSURL *)url
                 completionHandler:(void (^)(BOOL reachable))completionHandler;

@end


@interface OPReachabilityCondition ()

@property (copy, nonatomic) NSURL *host;

@end



@implementation OPReachabilityCondition


#pragma mark - OPOperationCondition Protocol
#pragma mark -

- (NSString *)name
{
    return @"Reachability";
}

- (BOOL)isMutuallyExclusive
{
    return NO;
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation
{
    return nil;
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus, NSError *))completion
{
    [[OPReachabilityController sharedInstance] requestReachabilityWithURL:[self host]
                                                        completionHandler:^(BOOL reachable) {
                                                            if (reachable) {
                                                                completion(OPOperationConditionResultStatusSatisfied, nil);
                                                            } else {
                                                                NSError *error = [NSError errorWithCode:OPOperationErrorCodeConditionFailed userInfo:@{
                                                                    kOPOperationConditionKey : [self name],
                                                                    kOPOperationHostKey : [self host]
                                                                }];
                                                                completion(OPOperationConditionResultStatusFailed, error);
                                                            }
                                                        }];
}


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)initWithHost:(NSURL *)host
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _host = [host copy];
    
    return self;
}

@end


@implementation OPReachabilityController


#pragma mark - Reachability
#pragma mark -

- (void)requestReachabilityWithURL:(NSURL *)url
                 completionHandler:(void (^)(BOOL reachable))completionHandler
{
    NSString *host = [url host];
    
    if (!host) {
        completionHandler(NO);
        return;
    }
    
    dispatch_async([self reachabilityQueue], ^{
        SCNetworkReachabilityRef ref = (__bridge SCNetworkReachabilityRef)(self.reachabilityRefs[host]);
        
        if (!ref) {
            ref = SCNetworkReachabilityCreateWithName(nil, [host UTF8String]);
        }
        
        if (ref) {
            self.reachabilityRefs[host] = (__bridge id)(ref);
            
            BOOL reachable = NO;
            SCNetworkReachabilityFlags flags = 0;
            if (SCNetworkReachabilityGetFlags(ref, &flags) != 0) {
                reachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
            }
            completionHandler(reachable);
        } else {
            completionHandler(NO);
        }
    });
}


#pragma mark - Lifecycle
#pragma mark -

+ (OPReachabilityController *)sharedInstance
{
    static OPReachabilityController *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OPReachabilityController alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _reachabilityQueue = dispatch_queue_create("Operative.Reachability", DISPATCH_QUEUE_SERIAL);
    _reachabilityRefs = [[NSMutableDictionary alloc] init];
    
    return self;
}

@end
