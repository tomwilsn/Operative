// ConditionsTests.m
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
#import <Operative/OPOperationConditionMutuallyExclusive.h>

@interface ConditionsTests : XCTestCase

@end

@implementation ConditionsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMutuallyExclusiveOperations {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should chain all mutually exclusive operations."];
    
    OPOperationQueue *operationQueue = [[OPOperationQueue alloc] init];
    NSMutableArray *operations = [[NSMutableArray alloc] init];
    
    __weak OPOperationQueue *weakQueue = operationQueue;
    
    // start operation will be the first to execute and it should verify that all mutually exclusive ops
    // are properly connected in a chain using dependencies.
    OPBlockOperation *startOperation = [[OPBlockOperation alloc] initWithMainQueueBlock:^{
        NSMutableArray *allOperations = [[weakQueue operations] mutableCopy];
        NSMutableArray *reversedOperations = [[[allOperations reverseObjectEnumerator] allObjects] mutableCopy];
        
        // check if operations were linked in a chain
        while(reversedOperations.count > 0) {
            OPOperation *followingOp = reversedOperations.firstObject;
            OPOperation *precedingOp = [reversedOperations objectAtIndex:1];
            
            // start operation is a block operation.
            if([precedingOp isKindOfClass:[OPBlockOperation class]]) {
                [expectation fulfill];
                return;
            }
            
            XCTAssertEqual(followingOp.dependencies.count, 1, @"Mutually exclusive ops are chained. Each op should have one dependency.");
            XCTAssertEqual(followingOp.dependencies.firstObject, precedingOp, @"Following operation should dependent on preceding operation.");
            
            [reversedOperations removeObject:followingOp];
        }
    }];
    
    for(NSInteger i = 0; i < 4; i++) {
        OPOperation *operation = [[OPOperation alloc] init];
        
        [operation addCondition:[[OPOperationConditionMutuallyExclusive alloc] initWithClass:[operation class]]];
        
        [operations addObject:operation];
    }
    
    // make first exclusive operation to run after startOperation.
    [operations.firstObject addDependency:startOperation];
    
    // insert start operation in the beginning to make it easier to verify mutual exclusivity
    [operations insertObject:startOperation atIndex:0];
    
    [operationQueue addOperations:operations waitUntilFinished:NO];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
