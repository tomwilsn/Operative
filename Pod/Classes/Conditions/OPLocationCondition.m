// OPLocationCondition.m
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


#import "OPLocationCondition.h"
#import "OPOperationConditionMutuallyExclusive.h"

#import "NSError+Operative.h"

#import <CoreLocation/CoreLocation.h>


NSString *const kOPLocationServicesEnabledKey = @"CLLocationServicesEnabled";
NSString *const kOPAuthorizationStatusKey = @"CLAuthorizationStatus";


/**
 *  A private `OPOperation` that will request permission to access the
 *  user's location, if permission has not already been granted.
 */
@interface OPLocationPermissionOperation : OPOperation <CLLocationManagerDelegate>

@property (assign, nonatomic) OPLocationConditionUsage usage;
@property (strong, nonatomic) CLLocationManager *manager;

- (instancetype)initWithUsage:(OPLocationConditionUsage)usage;

@end


@interface OPLocationCondition ()

@property (assign, nonatomic) OPLocationConditionUsage usage;

@end


#pragma mark - OPLocationCondition
#pragma mark -

@implementation OPLocationCondition

- (instancetype)initWithUsage:(OPLocationConditionUsage)usage
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _usage = usage;

    return self;
}

- (instancetype)init
{
    self = [self initWithUsage:OPLocationConditionWhenInUse];
    if (!self) {
        return nil;
    }
    
    return self;
}

- (NSString *)name
{
    return @"Location";
}

- (BOOL)isMutuallyExclusive
{
    return NO;
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation
{
    return [[OPLocationPermissionOperation alloc] initWithUsage:[self usage]];
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus result, NSError *error))completion
{
    BOOL enabled = [CLLocationManager locationServicesEnabled];
    CLAuthorizationStatus actual = [CLLocationManager authorizationStatus];

    // Satisfied until not
    OPOperationConditionResultStatus resultStatus = OPOperationConditionResultStatusSatisfied;

    NSError *error = nil;

    // There are several factors to consider when evaluating this condition
    if (enabled && actual == kCLAuthorizationStatusAuthorizedAlways) {
        // The service is enabled, and we have "Always" permission -> condition satisfied.
        // No-op
    } else if (enabled && ([self usage] == OPLocationConditionWhenInUse) && (actual == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        // The service is enabled, and we have "WhenInUse" permission -> condition satisfied.
        // No-op
    } else {
        /*
         * Anything else is an error. Maybe location services are disabled,
         * or maybe we need "Always" permission but only have "WhenInUse",
         * or maybe access has been restricted or denied,
         * or maybe access hasn't been request yet.
         *
         * This would happen if this condition were wrapped in a `SilentCondition`.
         */
        NSDictionary *userInfo = @{
            kOPOperationConditionKey : NSStringFromClass([self class]),
            kOPLocationServicesEnabledKey : @(enabled),
            kOPAuthorizationStatusKey : @(actual)
        };
        error = [NSError errorWithCode:OPOperationErrorCodeConditionFailed userInfo:userInfo];
        resultStatus = OPOperationConditionResultStatusFailed;
    }

    completion(resultStatus, error);
}

@end


#pragma mark - OPLocationPermissionOperation
#pragma mark -

@implementation OPLocationPermissionOperation

- (instancetype)initWithUsage:(OPLocationConditionUsage)usage
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _usage = usage;

    // This is an operation that potentially presents an alert so it should
    // be mutually exclusive with anything else that presents an alert.
    OPOperationConditionMutuallyExclusive *condition;
    Class cls = [UIAlertController class];
    condition = [[OPOperationConditionMutuallyExclusive alloc] initWithClass:cls];

    [self addCondition:condition];

    return self;
}

- (void)execute
{
    BOOL shouldRequestPermission = NO;

    // Not only do we need to handle the "Not Determined" case, but we also
    // need to handle the "upgrade" (WhenInUse -> Always) case.
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            shouldRequestPermission = YES;
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            switch ([self usage]) {
                case OPLocationConditionAlways:
                    shouldRequestPermission = YES;
                    break;
                default:
                    shouldRequestPermission = NO;
                    break;
            }
            break;
        }
        default:
            shouldRequestPermission = NO;
            break;
    }

    if (shouldRequestPermission) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self requestPermission];
        });
    } else {
        [self finish];
    }
}

- (void)requestPermission
{
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [self setManager:locationManager];

    NSString *key = nil;
    switch ([self usage]) {
        case OPLocationConditionWhenInUse:
            key = @"NSLocationWhenInUseUsageDescription";
            [self.manager requestWhenInUseAuthorization];
            break;

        case OPLocationConditionAlways:
            key = @"NSLocationAlwaysUsageDescription";
            [self.manager requestAlwaysAuthorization];
            break;
    }

    // This is helpful when developing the app.
    NSAssert([[NSBundle mainBundle] objectForInfoDictionaryKey:key] != nil, @"Requesting location permission requires the %@ key in your Info.plist", key);
}


#pragma mark - CLLocationManagerDelegate
#pragma mark -

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if ([self manager] == manager && [self isExecuting] && status != kCLAuthorizationStatusNotDetermined) {
        [self finish];
    }
}

@end



