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

#import <XCTest/XCTest.h>

#import <Operative/NSError+Operative.h>
#import <Operative/NSMutableDictionary+Operative.h>
#import <Operative/NSOperation+Operative.h>
#import <Operative/UIUserNotificationSettings+Operative.h>

@interface CategoriesTests : XCTestCase

@end

@implementation CategoriesTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - NSError category
#pragma mark -

- (void)testCreateErrorWithCodeAndUserInfo {
    NSDictionary *userInfo = @{@"test": @(YES)};
    NSError *error = [NSError errorWithCode:1 userInfo:userInfo];
    
    XCTAssertEqual(error.code, 1);
    XCTAssertEqualObjects(error.userInfo, userInfo);
    XCTAssertEqualObjects(error.domain, kOPOperationErrorDomain);
}

- (void)testCreateErrorWithCode {
    NSError *error = [NSError errorWithCode:1];
    
    XCTAssertEqual(error.code, 1);
    XCTAssertEqualObjects(error.userInfo, @{});
    XCTAssertEqualObjects(error.domain, kOPOperationErrorDomain);
}

#pragma mark - NSMutableDictionary category
#pragma mark -

- (void)testCreateDictionaryFromSet {
    NSSet *set = [NSSet setWithObjects:@{@"key": @"1", @"value": @"1"}, @{@"key": @"2", @"value": @"2"}, nil];
    
    NSMutableDictionary *dict = [NSMutableDictionary sequence:set keyMapper:^(id obj) {
        return obj[@"key"];
    }];
    
    XCTAssertEqual(dict.allKeys.count, 2);
    XCTAssertEqual([[dict[@"1"] allKeys] count], 2);
    XCTAssertEqual([[dict[@"2"] allKeys] count], 2);
    
    XCTAssertEqualObjects(dict[@"1"][@"key"], @"1");
    XCTAssertEqualObjects(dict[@"1"][@"value"], @"1");
    
    XCTAssertEqualObjects(dict[@"2"][@"key"], @"2");
    XCTAssertEqualObjects(dict[@"2"][@"value"], @"2");
}

- (void)testCreateDictionaryFromArray {
    NSArray *array = @[@{@"key": @"1", @"value": @"1"}, @{@"key": @"2", @"value": @"2"}];
    
    NSMutableDictionary *dict = [NSMutableDictionary sequence:array keyMapper:^(id obj) {
        return obj[@"key"];
    }];
    
    XCTAssertEqual(dict.allKeys.count, 2);
    XCTAssertEqual([[dict[@"1"] allKeys] count], 2);
    XCTAssertEqual([[dict[@"2"] allKeys] count], 2);
    
    XCTAssertEqualObjects(dict[@"1"][@"key"], @"1");
    XCTAssertEqualObjects(dict[@"1"][@"value"], @"1");
    
    XCTAssertEqualObjects(dict[@"2"][@"key"], @"2");
    XCTAssertEqualObjects(dict[@"2"][@"value"], @"2");
}

#pragma mark - NSOperation category
#pragma mark -

- (void)testAddMultipleDependencies {
    NSOperation *operation = [[NSOperation alloc] init];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i++)
    {
        [array addObject:[[NSOperation alloc] init]];
    }
    
    [operation addDependencies:array];
    
    XCTAssertEqual(operation.dependencies.count, 10);
}

- (void)testAddOriginalCompletionBlock {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should call original completion block"];
    
    NSOperation *operation = [[NSOperation alloc] init];
    operation.completionBlock = ^{
        [expectation fulfill];
    };
    
    [operation addCompletionBlock:^(void) {
    }];
    
    operation.completionBlock();
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testAddChainedCompletionBlock {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should call chained completion block"];
    
    NSOperation *operation = [[NSOperation alloc] init];
    operation.completionBlock = ^{
        
    };
    
    [operation addCompletionBlock:^(void) {
        [expectation fulfill];
    }];
    
    operation.completionBlock();
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - UIUserNotificationSettings category
#pragma mark -

- (void)testUserNotificationSettings {
    UIUserNotificationSettings *settings1;
    UIUserNotificationSettings *settings2;
    
    // All
    settings1 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
    // All minus alert
    settings2 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:nil];
    
    XCTAssertTrue([settings1 containsSettings:settings2]);
    XCTAssertFalse([settings2 containsSettings:settings1]);
    
    // All
    settings1 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
    // All minus sound
    settings2 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeAlert) categories:nil];
    XCTAssertTrue([settings1 containsSettings:settings2]);
    XCTAssertFalse([settings2 containsSettings:settings1]);
    
    // All
    settings1 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
    // All minus Badge
    settings2 = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
    XCTAssertTrue([settings1 containsSettings:settings2]);
    XCTAssertFalse([settings2 containsSettings:settings1]);
}

@end
