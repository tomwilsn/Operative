// OPLocationOperation.m
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


#import "OPLocationOperation.h"

#import "OPOperationConditionMutuallyExclusive.h"
#import "OPLocationCondition.h"

@interface OPLocationOperation () <CLLocationManagerDelegate>

@property (assign, nonatomic) CLLocationAccuracy accuracy;

@property (strong, nonatomic) CLLocationManager *manager;

@property (copy, nonatomic) void (^handler)(CLLocation *);

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end


@implementation OPLocationOperation


#pragma mark - Overrides
#pragma mark -

- (void)execute
{
    dispatch_async(dispatch_get_main_queue(), ^{
        /**
         *  `CLLocationManager` needs to be created on a thread with an active
         *  run loop, so for simplicity we do this on the main queue.
         */
        CLLocationManager *manager = [[CLLocationManager alloc] init];
        [manager setDesiredAccuracy:[self accuracy]];
        [manager setDelegate:self];
        [manager startUpdatingLocation];

        [self setManager:manager];
    });
}

- (void)cancel
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopLocationUpdates];
        [super cancel];
    });
}

- (void)stopLocationUpdates
{
    [self.manager stopUpdatingLocation];
    [self setManager:nil];
}


#pragma mark - CLLocationManagerDelegate
#pragma mark -

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [locations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLLocation *location = obj;
        if (location.horizontalAccuracy < [self accuracy]) {
            [self stopLocationUpdates];
            self.handler(location);
            [self finish];

            *stop = YES;
        }
    }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self stopLocationUpdates];
    [self finishWithError:error];
}


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)initWithAccuracy:(CLLocationAccuracy)accuracy
                 locationHandler:(void (^)(CLLocation *location))locationHandler
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _accuracy = accuracy;
    _handler = [locationHandler copy];

    [self addCondition:[[OPLocationCondition alloc] initWithUsage:OPLocationConditionWhenInUse]];
    [self addCondition:[[OPOperationConditionMutuallyExclusive alloc] initWithClass:[CLLocationManager class]]];

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
