// OPExclusivityController.h
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

#import <Foundation/Foundation.h>
#import "OPOperation.h"


/**
 *  `OPExclusivityController` is a singleton to keep track of all the in-flight
 *  `OPOperation` instances that have declared themselves as requiring mutual exclusivity.
 *  We use a singleton because mutual exclusivity must be enforced across the entire
 *  app, regardless of the `OPOperationQueue` on which an `OPOperation` was executed.
 */
@interface OPExclusivityController : NSObject

+ (OPExclusivityController *)sharedExclusivityController;

/**
 *  Registers an operation as being mutually exclusive
 *
 *  @param operation  OPOperation object which requires exclusivity
 *  @param categories Array of strings describing the name of the category of exclusivity
 *
 *  @return previous operations in categories.
 */
- (NSSet *)addOperation:(OPOperation *)operation categories:(NSArray *)categories;

/**
 *  Unregisters an operation from being mutually exclusive.
 *
 *  @param operation  OPOperation object which requires exclusivity
 *  @param categories Array of strings describing the name of the category of exclusivity
 */
- (void)removeOperation:(OPOperation *)operation categories:(NSArray *)categories;

@end
