//
//  StressTests.m
//  Operative
//
//  Created by pronebird on 4/13/16.
//  Copyright © 2016 Tom Wilson. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Operative/Operative.h>

/**
 *  This condition exists mainly for the purpose of keeping evaluator busy.
 */
@interface OPStressTestHollowCondition : NSObject <OPOperationCondition> @end

@implementation OPStressTestHollowCondition

- (BOOL)isMutuallyExclusive {
    return NO;
}

- (NSString *)name {
    return NSStringFromClass([self class]);
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation {
    return [[OPBlockOperation alloc] initWithMainQueueBlock:^{
        // whatever.
    }];
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus result, NSError *error))completion
{
    completion(OPOperationConditionResultStatusSatisfied, nil);
}

@end

@interface StressTests : XCTestCase

@end

@implementation StressTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Stress tests for mutually exclusive operations
#pragma mark -

- (void)testLotsOfMutuallyExclusiveOperations {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should finish 500,000 mutually exclusive operations."];
    OPOperationQueue *queue = [[OPOperationQueue alloc] init];
    
    [self cycleMutuallyExclusiveOperations:1 operationQueue:queue expectation:expectation];
    
    // time for coffee: give it 10 minutes
    [self waitForExpectationsWithTimeout:600 handler:nil];
}

- (void)cycleMutuallyExclusiveOperations:(NSInteger)take
                          operationQueue:(OPOperationQueue *)queue
                             expectation:(XCTestExpectation *)expectation
{
    NSMutableArray *operations = [[NSMutableArray alloc] init];
    
    OPBlockOperation *startOperation = [[OPBlockOperation alloc] initWithMainQueueBlock:^{
        NSLog(@"*** BEGIN TAKE %@ ***", @(take));
    }];
    
    startOperation.name = @"Start operation";
    
    __weak __typeof__(self) weakSelf = self;
    
    OPBlockOperation *finishOperation = [[OPBlockOperation alloc] initWithMainQueueBlock:^{
        NSLog(@"*** END TAKE %@ ***", @(take));
        
        if(take < 1000)
        {
            [weakSelf cycleMutuallyExclusiveOperations:(take + 1)
                                        operationQueue:queue
                                           expectation:expectation];
        }
        else
        {
            NSLog(@"*** THIS IS IT ***");
            
            [expectation fulfill];
        }
    }];
    finishOperation.name = @"Finish operation";
    
    for(NSInteger i = 0; i < 500; i++)
    {
        OPBlockOperation *op = [[OPBlockOperation alloc] initWithBlock:^(void (^completion)(void)) {
            // just do something async
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                completion();
            });
        }];
        
        op.name = [NSString stringWithFormat:@"Operation %@", @(i + 1)];
        
        // run one at a time
        [op addCondition:[OPOperationConditionMutuallyExclusive mutuallyExclusiveWith:[NSOperation class]]];
        
        [op addDependency:startOperation];
        [finishOperation addDependency:op];
        
        [operations addObject:op];
    }
    
    [operations addObject:startOperation];
    [operations addObject:finishOperation];
    
    NSLog(@"** ADD %@ operations **", @(operations.count));
    
    [queue addOperations:operations waitUntilFinished:NO];
}

#pragma mark - Stress tests for lots of async operations
#pragma mark -

- (void)testLotsOfAsyncOperations {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should finish 500,000 asynchronous operations."];
    OPOperationQueue *queue = [[OPOperationQueue alloc] init];
    
    [self cycleOperationsWithHollowCondition:1 operationQueue:queue expectation:expectation];
    
    // time for coffee: give it 10 minutes
    [self waitForExpectationsWithTimeout:600 handler:nil];
}

- (void)cycleOperationsWithHollowCondition:(NSInteger)take
                            operationQueue:(OPOperationQueue *)queue
                               expectation:(XCTestExpectation *)expectation
{
    NSMutableArray *operations = [[NSMutableArray alloc] init];
    
    OPBlockOperation *startOperation = [[OPBlockOperation alloc] initWithMainQueueBlock:^{
        NSLog(@"*** BEGIN TAKE %@ ***", @(take));
    }];
    
    startOperation.name = @"Start operation";
    
    __weak __typeof__(self) weakSelf = self;
    
    OPBlockOperation *finishOperation = [[OPBlockOperation alloc] initWithMainQueueBlock:^{
        NSLog(@"*** END TAKE %@ ***", @(take));
        
        if(take < 1000)
        {
            [weakSelf cycleOperationsWithHollowCondition:(take + 1)
                                          operationQueue:queue
                                             expectation:expectation];
        }
        else
        {
            NSLog(@"*** THIS IS IT ***");
            
            [expectation fulfill];
        }
    }];
    finishOperation.name = @"Finish operation";
    
    for(NSInteger i = 0; i < 500; i++)
    {
        OPBlockOperation *op = [[OPBlockOperation alloc] initWithBlock:^(void (^completion)(void)) {
            // just do something async
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                completion();
            });
        }];
        
        op.name = [NSString stringWithFormat:@"Operation %@", @(i + 1)];
        
        // just to keep evaluator doing something
        [op addCondition:[[OPStressTestHollowCondition alloc] init]];
        
        [op addDependency:startOperation];
        [finishOperation addDependency:op];
        
        [operations addObject:op];
    }
    
    [operations addObject:startOperation];
    [operations addObject:finishOperation];
    
    NSLog(@"** ADD %@ operations **", @(operations.count));
    
    [queue addOperations:operations waitUntilFinished:NO];
}

@end
