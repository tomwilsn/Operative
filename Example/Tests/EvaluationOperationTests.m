//
//  EvaluationOperationTests.m
//  Operative
//
//  Created by pronebird on 4/14/16.
//  Copyright © 2016 Tom Wilson. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Operative/Operative.h>


//
// OPEvaluationTestState used to describe operation lifecycle.
//

typedef NS_ENUM(NSInteger, OPEvaluationTestState) {
    OPEvaluationTestStateInitialized,
    
    OPEvaluationTestStateBeganDependency,
    OPEvaluationTestStateFinishedDependency,
    
    OPEvaluationTestStateBeganEvaluation,
    OPEvaluationTestStateFinishedEvaluation,
    
    OPEvaluationTestStateBeganOperation,
    OPEvaluationTestStateFinishedOperation
};


//
// Convert OPEvaluationTestState to NSString
//

static NSString * NSStringFromOPEvaluationTestState(OPEvaluationTestState state) {
    switch (state) {
        case OPEvaluationTestStateInitialized: return @"Initialized";
        case OPEvaluationTestStateBeganDependency: return @"BeganDependency";
        case OPEvaluationTestStateFinishedDependency: return @"FinishedDependency";
        case OPEvaluationTestStateBeganEvaluation: return @"BeganEvaluation";
        case OPEvaluationTestStateFinishedEvaluation: return @"FinishedEvaluation";
        case OPEvaluationTestStateBeganOperation: return @"BeganOperation";
        case OPEvaluationTestStateFinishedOperation: return @"FinishedOperation";
    }
}


//
// Test observer used to validate the state transition.
//

@interface OPEvaluationTestObserver : NSObject

- (instancetype)initWithExpectation:(XCTestExpectation *)expectation failureBlock:(void(^)(NSString *error))failureBlock;

- (void)didChangeState:(OPEvaluationTestState)newState targetOperation:(OPOperation *)operation;

@end

@implementation OPEvaluationTestObserver {
    XCTestExpectation *_expectation;
    OPEvaluationTestState _state;
    void(^_failureBlock)(NSString *error);
}

- (instancetype)initWithExpectation:(XCTestExpectation *)expectation failureBlock:(void(^)(NSString *error))failureBlock {
    NSParameterAssert(expectation);
    
    self = [super init];
    if(!self) {
        return nil;
    }
    
    _expectation = expectation;
    _state = OPEvaluationTestStateInitialized;
    _failureBlock = failureBlock;
    
    return self;
}

- (void)didChangeState:(OPEvaluationTestState)newState targetOperation:(OPOperation *)operation {
    @synchronized (self) {
        if(![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didChangeState:newState targetOperation:operation];
            });
            return;
        }
        
        if(newState <= _state) {
            _failureBlock(@"observeStateChange is called out of order.");
            return;
        }
        
        NSLog(@"%@: Change state %@", [operation description], NSStringFromOPEvaluationTestState(newState));
        
        _state = newState;
        
        if(_state == OPEvaluationTestStateFinishedOperation) {
            [_expectation fulfill];
        }
    }
}

@end


//
// Test condition that notifies test observer as condition evaluation proceeds.
//

@interface OPEvaluationOperationTestCondition : NSObject<OPOperationCondition>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTestObserver:(OPEvaluationTestObserver *)testObserver;

@end

@implementation OPEvaluationOperationTestCondition {
    OPEvaluationTestObserver *_testObserver;
}

- (instancetype)initWithTestObserver:(OPEvaluationTestObserver *)testObserver
{
    NSParameterAssert(testObserver);
    
    self = [super init];
    if(!self) {
        return nil;
    }
    
    _testObserver = testObserver;
    
    return self;
}

- (BOOL)isMutuallyExclusive {
    return NO;
}

- (NSString *)name {
    return NSStringFromClass([self class]);
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation {
    OPBlockOperation *dependency = [[OPBlockOperation alloc] initWithBlock:^(void (^completion)(void)) {
        // simulate some work
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completion();
        });
    }];
    OPEvaluationTestObserver *testObserver = _testObserver;
    
    __weak OPOperation *weakOperation = operation;
    
    [dependency addObserver:[[OPBlockObserver alloc] initWithStartHandler:^(OPOperation *anOperation) {
        [testObserver didChangeState:OPEvaluationTestStateBeganDependency targetOperation:weakOperation];
    } produceHandler:^(OPOperation *operation, NSOperation *newOperation) {
        
    } finishHandler:^(OPOperation *anOperation, NSArray *errors) {
        [testObserver didChangeState:OPEvaluationTestStateFinishedDependency targetOperation:weakOperation];
    }]];
    
    return dependency;
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus result, NSError *error))completion
{
    [_testObserver didChangeState:OPEvaluationTestStateBeganEvaluation targetOperation:operation];
    
    // simulate async evaluation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        
        [_testObserver didChangeState:OPEvaluationTestStateFinishedEvaluation targetOperation:operation];
        
        completion(OPOperationConditionResultStatusSatisfied, nil);
    });
}

@end

//
// Condition with dependency that produces mutually exclusive operation
//

@interface OPEvaluationTestOperationProducingCondition : NSObject<OPOperationCondition>

@end

@implementation OPEvaluationTestOperationProducingCondition

- (BOOL)isMutuallyExclusive {
    return NO;
}

- (NSString *)name {
    return NSStringFromClass([self class]);
}

- (NSOperation *)dependencyForOperation:(OPOperation *)operation {
    return [[OPBlockOperation alloc] initWithMainQueueBlock:^{
        OPBlockOperation *exclusiveOp = [[OPBlockOperation alloc] initWithMainQueueBlock:^{
            NSLog(@"Run produced operation.");
        }];
        
        [exclusiveOp addCondition:[OPOperationConditionMutuallyExclusive mutuallyExclusiveWith:[NSOperation class]]];
        
        [operation produceOperation:exclusiveOp];
    }];
}

- (void)evaluateConditionForOperation:(OPOperation *)operation
                           completion:(void (^)(OPOperationConditionResultStatus result, NSError *error))completion
{
    completion(OPOperationConditionResultStatusSatisfied, nil);
}

@end


//
// Evaluation Operation Tests
//

@interface EvaluationOperationTests : XCTestCase

@end

@implementation EvaluationOperationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//
// Make sure that operations execute in the right order:
//
// 1. Run dependencies
// 2. Run evaluation
// 3. Run operation
//
//

- (void)testOperationEvaluationOrder
{
    OPOperationQueue *queue = [[OPOperationQueue alloc] init];

    for(NSInteger i = 0; i < 5; i++)
    {
        OPBlockOperation *targetOperation = [[OPBlockOperation alloc] initWithBlock:^(void (^completion)(void)) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completion();
            });
        }];
        
        targetOperation.name = [NSString stringWithFormat:@"Operation %@", @(i + 1)];

        // Create expectation
        XCTestExpectation *expectation = [self expectationWithDescription:@"Should run a sequence of: condition dependencies, condition evaluation, relevant operation."];

        // Create test observer to follow the state change
        OPEvaluationTestObserver *testObserver = [[OPEvaluationTestObserver alloc] initWithExpectation:expectation failureBlock:^(NSString *error) {
            XCTFail(@"%@", error);
        }];
        
        // create test condition notifying state observer
        OPEvaluationOperationTestCondition *testCondition = [[OPEvaluationOperationTestCondition alloc] initWithTestObserver:testObserver];
        
        // notify state observer regarding operation progress
        [targetOperation addObserver:[[OPBlockObserver alloc] initWithStartHandler:^(OPOperation *operation) {
            [testObserver didChangeState:OPEvaluationTestStateBeganOperation targetOperation:operation];
        } produceHandler:^(OPOperation *operation, NSOperation *newOperation) {
            
        } finishHandler:^(OPOperation *operation, NSArray *errors) {
            [testObserver didChangeState:OPEvaluationTestStateFinishedOperation targetOperation:operation];
        }]];
        
        // add condition to target operation
        [targetOperation addCondition:testCondition];
        
        [queue addOperation:targetOperation];
    }
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

//
// Make sure that mutually exclusive operations run in sequence
//

- (void)testMutuallyExclusiveOperations {
    OPOperationQueue *queue = [[OPOperationQueue alloc] init];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect this to run sequentially."];
    NSMutableArray *operations = [[NSMutableArray alloc] init];
    
    for(NSInteger i = 0; i < 10; i++)
    {
        OPBlockOperation *operation = [[OPBlockOperation alloc] initWithBlock:^(void (^completion)(void)) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                NSLog(@"Run operation %@", @(i + 1));
                completion();
            });
        }];
        
        operation.name = [NSString stringWithFormat:@"Operation %@", @(i + 1)];
        
        [operation addObserver:[[OPBlockObserver alloc] initWithFinishHandler:^(OPOperation *operation, NSArray *errors) {
            @synchronized(operations) {
                [operations removeObject:operation];
                
                OPOperation *nextOp = operations.firstObject;
                
                if(nextOp)
                {
                    //
                    // Condition evaluation group for mutually exclusive operation should have dependency set to previous target operation
                    //
                    XCTAssertFalse(nextOp.isReady, @"Next mutually exclusive operation should not be ready yet.");
                    XCTAssertTrue([nextOp.dependencies containsObject:operation], @"Next operation should depend on previous exclusive operation. Next operation: %@, dependencies: %@. Previous operation: %@", nextOp, nextOp.dependencies, operation);
                }
                else
                {
                    [expectation fulfill];
                }
            }
        }]];
        
        [operation addCondition:[OPOperationConditionMutuallyExclusive mutuallyExclusiveWith:[NSOperation class]]];
        
        [operations addObject:operation];
    }
    
    [queue addOperations:operations waitUntilFinished:NO];
    
    [self waitForExpectationsWithTimeout:20 handler:nil];
}

//
// Make sure that queue does not deadlock if conditions produce mutually exclusive
// operations with the same categories as relevant operations
//

- (void)testProduceMutuallyExclusiveOperationFromConditionDependencyShouldNotDeadlock
{
    OPOperationQueue *queue = [[OPOperationQueue alloc] init];
    
    // queue should be drained
    [self keyValueObservingExpectationForObject:queue keyPath:@"operationCount" expectedValue:@0];
    
    for(NSInteger i = 0; i < 10; i++) {
        OPBlockOperation *operation = [[OPBlockOperation alloc] initWithMainQueueBlock:^{
            NSLog(@"Run operation %@", @(i + 1));
        }];
        
        operation.name = [NSString stringWithFormat:@"Operation %@", @(i + 1)];
        
        [operation addCondition:[[OPEvaluationTestOperationProducingCondition alloc] init]];
        [operation addCondition:[OPOperationConditionMutuallyExclusive mutuallyExclusiveWith:[NSOperation class]]];
        
        [queue addOperation:operation];
    }
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
