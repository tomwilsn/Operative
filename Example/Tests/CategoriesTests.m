// CategoriesTests.m
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

// https://github.com/Specta/Specta

#import <Operative/NSError+OPOperationErrors.h>
#import <Operative/NSMutableDictionary+Operator.h>
#import <Operative/NSOperation+Operator.h>
#import <Operative/UIUserNotificationSettings+Operator.h>

SpecBegin(CategoriesTests)

describe(@"NSError", ^{
    
    it(@"can create error with code and user info", ^{
        NSDictionary *userInfo = @{@"test": @(YES)};
        NSError *error = [NSError errorWithCode:1 userInfo:userInfo];

        expect(error.code).equal(1);
        expect(error.userInfo).beIdenticalTo(userInfo);
        expect(error.domain).equal(kOPOperationErrorDomain);
    });
    
    it(@"can create error with just a code", ^{
        NSError *error = [NSError errorWithCode:1];
        expect(error.code).equal(1);
        expect(error.userInfo).to.beEmpty();
        expect(error.domain).equal(kOPOperationErrorDomain);
    });
});

describe(@"NSMutableDictionary", ^{
    it(@"can create a dictionary from a NSSet", ^{
        NSSet *set = [NSSet setWithObjects:@{@"key": @"1", @"value": @"1"}, @{@"key": @"2", @"value": @"2"}, nil];
        
        NSMutableDictionary *dict = [NSMutableDictionary sequence:set keyMapper:^(id obj) {
            return obj[@"key"];
        }];
        
        expect(dict).to.haveCountOf(2);
        expect(dict[@"1"]).to.haveCountOf(2);
        expect(dict[@"2"]).to.haveCountOf(2);
        
        expect(dict[@"1"][@"key"]).equal(@"1");
        expect(dict[@"1"][@"value"]).equal(@"1");
        
        expect(dict[@"2"][@"key"]).equal(@"2");
        expect(dict[@"2"][@"value"]).equal(@"2");
    });
    it(@"can create a dictionary from a NSArray", ^{
        NSArray *array = @[@{@"key": @"1", @"value": @"1"}, @{@"key": @"2", @"value": @"2"}];
        
        NSMutableDictionary *dict = [NSMutableDictionary sequence:array keyMapper:^(id obj) {
            return obj[@"key"];
        }];
        
        expect(dict).to.haveCountOf(2);
        expect(dict[@"1"]).to.haveCountOf(2);
        expect(dict[@"2"]).to.haveCountOf(2);
        
        expect(dict[@"1"][@"key"]).equal(@"1");
        expect(dict[@"1"][@"value"]).equal(@"1");
        
        expect(dict[@"2"][@"key"]).equal(@"2");
        expect(dict[@"2"][@"value"]).equal(@"2");
    });
});

describe(@"NSOperation", ^{
    it(@"can add multiple dependencies", ^{
        NSOperation *operation = [[NSOperation alloc] init];
        
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (int i = 0; i < 10; i++)
        {
            [array addObject:[[NSOperation alloc] init]];
        }
        
        [operation addDependencies:array];
        
        expect(operation.dependencies).to.haveCountOf(10);
    });
    
    it(@"can add completion block - test original", ^{
        waitUntil(^(DoneCallback done) {
            NSOperation *operation = [[NSOperation alloc] init];
            operation.completionBlock = ^{
                done();
            };
            
            [operation addCompletionBlock:^(void) {
            }];
            
            operation.completionBlock();
        });

    });
    it(@"can add completion block - test added", ^{
        waitUntil(^(DoneCallback done) {
            NSOperation *operation = [[NSOperation alloc] init];
            operation.completionBlock = ^{
            };
            
            [operation addCompletionBlock:^(void) {
                done();
            }];
            
            operation.completionBlock();
        });
        
    });
});

describe(@"UIUserNotificationSettings", ^{
    it(@"can figure out if contains another set of settings - types", ^{
        
        UIUserNotificationSettings *settings1;
        UIUserNotificationSettings *settings2;

        // All
        settings1 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
        // All minus alert
        settings2 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:nil];
        expect([settings1 containsSettings:settings2]).to.beTruthy();
        expect([settings2 containsSettings:settings1]).to.beFalsy();

        // All
        settings1 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
        // All minus sound
        settings2 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeAlert) categories:nil];
        expect([settings1 containsSettings:settings2]).to.beTruthy();
        expect([settings2 containsSettings:settings1]).to.beFalsy();

        // All
        settings1 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
        // All minus Badge
        settings2 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
        expect([settings1 containsSettings:settings2]).to.beTruthy();
        expect([settings2 containsSettings:settings1]).to.beFalsy();
    });
    
    it(@"can figure out if settings contains another set of settings - categories", ^{
        // TODO
    });
});


SpecEnd
