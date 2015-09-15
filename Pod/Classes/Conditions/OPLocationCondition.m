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
#import "NSError+OPOperationErrors.h"

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NSString * const kOPLocationServicesEnabledKey = @"CLLocationServicesEnabled";
NSString * const kOPAuthorizationStatusKey = @"CLAuthorizationStatus";

@interface OPLocationPermissionOperation : OPOperation <CLLocationManagerDelegate>

@property (assign, nonatomic) OPLocationConditionUsage usage;
@property (strong, nonatomic) CLLocationManager *manager;

@end

@implementation OPLocationPermissionOperation

- (instancetype) initWithUsage:(OPLocationConditionUsage) usage
{
    self = [super init];
    if (self)
    {
        _usage = usage;
        
        [self addCondition:[[OPOperationConditionMutuallyExclusive alloc] initWithClass:[UIAlertController class]]];
    }
    return self;
}

- (void) execute
{
    BOOL shouldRequestPermission = NO;
    
    switch ([CLLocationManager authorizationStatus])
    {
        case kCLAuthorizationStatusNotDetermined:
            shouldRequestPermission = YES;
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            switch (self.usage)
            {
                case OPLocationConditionAlways:
                    shouldRequestPermission = YES;
                    break;
                default:
                    shouldRequestPermission = NO;
            }
            break;
        }
        default:
            shouldRequestPermission = NO;
    }
    
    if (shouldRequestPermission)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self requestPermission];
        });
    }
    else
    {
        [self finish];
    }
}

- (void) requestPermission
{
    self.manager = [[CLLocationManager alloc] init];
    self.manager.delegate = self;
    
    NSString *key = nil;
    switch (_usage)
    {
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

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (manager == self.manager && self.isExecuting && status != kCLAuthorizationStatusNotDetermined)
    {
        [self finish];
    }
}

@end


@interface OPLocationCondition()

@property (assign, nonatomic) OPLocationConditionUsage usage;

@end

@implementation OPLocationCondition

- (instancetype) initWithUsage:(OPLocationConditionUsage) usage
{
    self = [super init];
    if (self)
    {
        _usage = usage;
    }
    return self;
}

- (NSString *) name
{
    return @"Location";
}

- (BOOL) isMutuallyExclusive
{
    return NO;
}

- (NSOperation *) dependencyForOperation:(OPOperation *)operation
{
    return [[OPLocationPermissionOperation alloc] initWithUsage:self.usage];
}

- (void) evaluateConditionForOperation:(OPOperation *)operation completion:(void (^)(NSError *))completion
{
    BOOL enabled = [CLLocationManager locationServicesEnabled];
    CLAuthorizationStatus actual = [CLLocationManager authorizationStatus];
    
    NSError *error = nil;
    
    if (enabled && actual == kCLAuthorizationStatusAuthorizedAlways)
    {
        // nothing..
    }
    else if (enabled && (self.usage == OPLocationConditionWhenInUse) && (actual == kCLAuthorizationStatusAuthorizedWhenInUse))
    {
        // nothing..
    }
    else
    {
        error = [NSError errorWithCode:OPOperationErrorCodeConditionFailed userInfo:@{
                                                                                      kOPOperationConditionKey: NSStringFromClass(self.class),
                                                                                      kOPLocationServicesEnabledKey: @(enabled),
                                                                                      kOPAuthorizationStatusKey: @(actual)
                                                                                      
                                                                                      }];
    }
    
    completion(error);
}

@end
