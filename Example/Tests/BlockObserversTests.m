//
//  BlockObserversTests.m
//  Operative
//
//  Created by pronebird on 11/7/15.
//  Copyright © 2015 Tom Wilson. All rights reserved.
//

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
