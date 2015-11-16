// BlockObserversTests.m
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

#import <Operative/Operative.h>

@interface BlockObserversTests : XCTestCase

@end

@implementation BlockObserversTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStartHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Block observer should call start handler"];
    
    OPOperationQueue *operationQueue = [[OPOperationQueue alloc] init];
    OPOperation *operation = [[OPOperation alloc] init];
    
    [operation addObserver:[[OPBlockObserver alloc] initWithStartHandler:^(OPOperation *operation) {
        [expectation fulfill];
    } produceHandler:^(OPOperation *operation, NSOperation *newOperation) {
        
    } finishHandler:^(OPOperation *operation, NSArray *errors) {
        
    }]];
    
    [operationQueue addOperation:operation];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testFinishHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Block observer should call finish handler"];
    
    OPOperationQueue *operationQueue = [[OPOperationQueue alloc] init];
    OPOperation *operation = [[OPOperation alloc] init];
    
    [operation addObserver:[[OPBlockObserver alloc] initWithStartHandler:^(OPOperation *operation) {
        
    } produceHandler:^(OPOperation *operation, NSOperation *newOperation) {
        
    } finishHandler:^(OPOperation *operation, NSArray *errors) {
        [expectation fulfill];
    }]];
    
    [operationQueue addOperation:operation];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testProduceHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Block observer should call produce handler"];
    
    OPOperationQueue *operationQueue = [[OPOperationQueue alloc] init];
    OPOperation *operation = [[OPOperation alloc] init];
    
    [operation addObserver:[[OPBlockObserver alloc] initWithStartHandler:^(OPOperation *operation) {
        
    } produceHandler:^(OPOperation *operation, NSOperation *newOperation) {
        [expectation fulfill];
    } finishHandler:^(OPOperation *operation, NSArray *errors) {
        [operation produceOperation:[[OPOperation alloc] init]];
    }]];
    
    [operationQueue addOperation:operation];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
