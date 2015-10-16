// OPRemoteNotificationCondition.h
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

#import "OPOperationCondition.h"


/**
 *  A condition for verifying that the app has the ability to receive push notifications.
 */
@interface OPRemoteNotificationCondition : NSObject <OPOperationCondition>

/**
 *  Class method called upon by `UIApplication` when a remote notification
 *  push token has been received.
 *  Either this method or -didFailToRegister: should be called during
 *  the remote notification registration process.
 *
 *  @param token `NSData` object received upon successful remote notification registration
 */
+ (void)didReceiveNotificationToken:(NSData *)token;

/**
 *  Class method called upon by `UIApplication` when a remote notification
 *  registration process failed with an error.
 *  Either this method or -didReceiveNotificationToken: should be called during
 *  the remote notification registration process.
 *
 *  @param error `NSError` object describing the failed registration
 */
+ (void)didFailToRegister:(NSError *)error;

@end
