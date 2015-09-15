// OPAlertOperation.m
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

#if TARGET_OS_IPHONE

#import "OPAlertOperation.h"
#import "OPOperationConditionMutuallyExclusive.h"


@interface OPAlertOperation()

@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIViewController *presentationContext;

@end

@implementation OPAlertOperation


- (NSString *) title
{
    return _alertController.title;
}

- (void) setTitle:(NSString *)title
{
    _alertController.title = title;
}

- (NSString *) message
{
    return _alertController.message;
}

- (void) setMessage:(NSString *)message
{
    _alertController.message = message;
}

- (instancetype) initWithPresentationContext:(UIViewController *)viewController
{
    self = [super init];
    
    if (self)
    {
        self.presentationContext = viewController ? viewController : [UIApplication sharedApplication].keyWindow.rootViewController;
        
        _alertController = [[UIAlertController alloc] init];
        
        
        [self addCondition:[OPOperationConditionMutuallyExclusive mutuallyExclusiveWith:[UIAlertController class]]];

        [self addCondition:[OPOperationConditionMutuallyExclusive mutuallyExclusiveWith:[UIViewController class]]];
    }
    return self;
}

- (void) addAction:(NSString *) title style:(UIAlertActionStyle) style handler:(void (^)(OPAlertOperation *))handler;
{
    __weak __typeof__(self) weakSelf = self;

    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:style handler:^(UIAlertAction *action) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (handler) handler(strongSelf);
        
        [weakSelf finish];
    }];
    
    [_alertController addAction:action];
}

#pragma mark - OPOperation Overrides

- (void) execute
{
    if (!_presentationContext)
    {
        [self finish];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.alertController.actions.count == 0) {
            [self addAction:@"OK" style:UIAlertActionStyleDefault handler:nil];
        }
        
        [_presentationContext presentViewController:_alertController animated:YES completion:nil];
    });
}

- (void) cancel
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_alertController dismissViewControllerAnimated:YES completion:^{
            [super cancel];
        }];
    });
}

@end

#endif
