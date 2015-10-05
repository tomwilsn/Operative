// OPViewController.m
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

#import "OPViewController.h"
#import <Operative/Operative.h>

#import "GroupOperationTest.h"

@interface OPViewController ()

@property (strong, nonatomic) OPOperationQueue *queue;

@end

@implementation OPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    OPDelayOperation *delay = [[OPDelayOperation alloc] initWithTimeInterval:10.0f];
    [self.queue addOperation:delay];

    // Alert options - one at a time!
    for (NSUInteger i = 0; i < 5; i++) {
        OPAlertOperation *operation = [[OPAlertOperation alloc] initWithPresentationContext:self];
        operation.title = [NSString stringWithFormat:@"Alert #%lu", (unsigned long)i];
        [operation addDependency:delay];
        [self.queue addOperation:operation];
    }
    
//    [delay cancel];
    
    //
    // Block operations
    //
    // Background block
    OPBlockOperation *background = [[OPBlockOperation alloc] initWithBlock:^(void(^completion)(void)) {
        NSLog(@"Background block operation on main thread: %i", [NSThread isMainThread]);
        completion();
    }];
    [background addObserver:[[OPBlockObserver alloc] initWithStartHandler:^(OPOperation *operation) {
        NSLog(@"Background block operation started!");
    } produceHandler:nil
                                                            finishHandler:^(OPOperation *operation, NSArray *errors) {
                                                                NSLog(@"Background block operation finished!");
                                                            }]];
    
    // Main thread block
    OPBlockOperation *mainThread = [[OPBlockOperation alloc] initWithMainQueueBlock:^{
        NSLog(@"Main Thread block operation on main thread: %i", [NSThread isMainThread]);
    }];
    [mainThread addObserver:[[OPBlockObserver alloc] initWithStartHandler:^(OPOperation *operation) {
        NSLog(@"Main Thread block operation started!");
    } produceHandler:nil
                                                            finishHandler:^(OPOperation *operation, NSArray *errors) {
                                                                NSLog(@"Main Thread block operation finished!");
                                                            }]];

    // Start them
    [self.queue addOperation:background];
    [self.queue addOperation:mainThread];
    
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    
    // 1
    sessionConfig.allowsCellularAccess = YES;
    
    // 2
    [sessionConfig setHTTPAdditionalHeaders:
     @{@"Accept": @"application/json"}];
    
    // 3
    sessionConfig.timeoutIntervalForRequest = 30.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    
    NSURLSessionTask *sessionTask = [session dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.github.com/repos/elixir-lang/elixir/issues"]]
                                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//                                                   NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//                                                   NSLog(@"%@", dict.description);
                                               }];
    
    OPURLSessionTaskOperation *urlOperation = [[OPURLSessionTaskOperation alloc] initWithTask:sessionTask];
    
    [urlOperation addObserver:[[OPBlockObserver alloc] initWithStartHandler:^(OPOperation *operation) {
        NSLog(@"URL Operation started!");
    }
                                                             produceHandler:^(OPOperation *operation, NSOperation *newOperation) {
                                                             } finishHandler:^(OPOperation *operation, NSArray *errors) {
                                                                 NSLog(@"URL Operation finished");
                                                                 NSLog(@"%@", sessionTask.response);
                                                             }]];
    
    [self.queue addOperation:urlOperation];
    
    
    // Group operation
    
    GroupOperationTest *groupTest = [[GroupOperationTest alloc] init];
    [groupTest addObserver:[[OPBlockObserver alloc] initWithStartHandler:^(OPOperation *operation) {
        NSLog(@"Group operation started");
    } produceHandler:^(OPOperation *operation, NSOperation *newOperation) {
        NSLog(@"Group operation produced operation: %@", operation);
    } finishHandler:^(OPOperation *operation, NSArray *errors) {
        NSLog(@"Group operation completed!");
    }]];
    [self.queue addOperation:groupTest];
    
    
    
    
    
    // Location Test
    OPLocationOperation *locationOperation = [[OPLocationOperation alloc] initWithAccuracy:1000.f
                                                                           locationHandler:^(CLLocation *location) {
                                                                               NSLog(@"Got location: %f, %f", location.coordinate.latitude, location.coordinate.longitude);
                                                                           }];
    
    [self.queue addOperation:locationOperation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Properties

- (OPOperationQueue *) queue
{
    if (!_queue)
    {
        _queue = [[OPOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 5;
    }
    return _queue;
    
}
@end
