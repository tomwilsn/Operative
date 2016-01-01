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


@interface OPAlertOperation ()

@property (strong, nonatomic) UIAlertController *alertController;

@property (strong, nonatomic) UIViewController *presentationContext;

@end


@implementation OPAlertOperation


#pragma mark - Add Action
#pragma mark -

- (void)addAction:(NSString *)title
            style:(UIAlertActionStyle)style
          handler:(void (^)(OPAlertOperation *))handler;
{
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:style handler:^(UIAlertAction *action) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (handler) {
            handler(strongSelf);
        }
        
        [strongSelf finish];
    }];
    
    [self.alertController addAction:action];
}


#pragma mark - Overrides
#pragma mark -

- (void)execute
{
    if (![self presentationContext]) {
        [self finish];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if([self isCancelled]) {
            return;
        }
        
        if ([self.alertController.actions count] == 0) {
            [self addAction:@"OK" style:UIAlertActionStyleDefault handler:nil];
        }

        [self.presentationContext presentViewController:[self alertController] animated:YES completion:nil];
    });
}

- (void)cancel
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.alertController.presentingViewController)
        {
            [self.alertController dismissViewControllerAnimated:YES completion:^{
                [super cancel];
            }];
        }
        else
        {
            [super cancel];
        }
    });
}


#pragma mark - Getters / Setters
#pragma mark -

- (NSString *)title
{
    return [self.alertController title];
}

- (void)setTitle:(NSString *)title
{
    [self.alertController setTitle:[title copy]];
}

- (NSString *)message
{
    return [self.alertController message];
}

- (void)setMessage:(NSString *)message
{
    [self.alertController setMessage:[message copy]];
}


#pragma mark - Lifecycle
#pragma mark -

- (instancetype)initWithPresentationContext:(UIViewController *)presentationContext
{
    self = [self initWithPresentationContext:presentationContext
                              preferredStyle:UIAlertControllerStyleActionSheet];
    if (!self) {
        return nil;
    }

    return self;
}

- (instancetype)initWithPresentationContext:(UIViewController *)presentationContext
                             preferredStyle:(UIAlertControllerStyle)preferredStyle
{
    self = [super init];

    if (!self) {
        return nil;
    }

    _alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:preferredStyle];
    
    _presentationContext = presentationContext ?: [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    [self addCondition:[OPOperationConditionMutuallyExclusive alertPresentationExclusivity]];
    
    /**
     *  This operation modifies the view controller hierarchy.
     *  Doing this while other such operations are executing can lead to
     *  inconsistencies in UIKit. So, let's make them mutally exclusive.
     */
    [self addCondition:[OPOperationConditionMutuallyExclusive mutuallyExclusiveWith:[UIViewController class]]];

    return self;
}

@end

#endif
