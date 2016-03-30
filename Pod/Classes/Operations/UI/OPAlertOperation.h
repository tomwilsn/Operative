// OPAlertOperation.h
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

#import "OPOperation.h"

#import <UIKit/UIKit.h>


@interface OPAlertOperation : OPOperation

/**
 *  Initializes an instance of OPAlertOperation with the contained
 *  UIAlertController's UIAlertControllerStyle defaulted to
 *  UIAlertControllerStyleActionSheet
 *
 *  @see -initWithPresentationContext:preferredStyle
 *
 *  @param presentationContext UIViewController from which the UIAlertController
 *                             will be present. If nil then this will default to
 *                             the rootViewController of the sharedApplication.
 *
 *  @return An initialized OPAlertOperation
 */
- (instancetype)initWithPresentationContext:(UIViewController *)presentationContext;

- (instancetype)initWithPresentationContext:(UIViewController *)presentationContext
                             preferredStyle:(UIAlertControllerStyle)preferredStyle NS_DESIGNATED_INITIALIZER;

/**
 *  Unused `-init` method.
 *  @see -initWithPresentationContext:
 */
- (instancetype)init NS_UNAVAILABLE;

@property (copy, nonatomic) NSString *title;

@property (copy, nonatomic) NSString *message;

- (void)addAction:(NSString *)title
            style:(UIAlertActionStyle)style
          handler:(void (^)(OPAlertOperation *alertOperation))handler;

@end

#endif