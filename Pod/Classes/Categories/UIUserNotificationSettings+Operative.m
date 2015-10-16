// UIUserNotificationSettings+Operative.m
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

#import "UIUserNotificationSettings+Operative.h"
#import "NSMutableDictionary+Operative.h"

@implementation UIUserNotificationSettings (Operative)

- (BOOL)containsSettings:(UIUserNotificationSettings *)settings;
{
    if (((self.types & UIUserNotificationTypeBadge) == 0) &&
        ((settings.types & UIUserNotificationTypeBadge) != 0)) {
        return NO;
    } else if (((self.types & UIUserNotificationTypeSound) == 0) &&
               ((settings.types & UIUserNotificationTypeSound) != 0)) {
        return NO;
    } else if (((self.types & UIUserNotificationTypeAlert) == 0) &&
               ((settings.types & UIUserNotificationTypeAlert) != 0)) {
        return NO;
    }

    NSSet *otherCategories = settings.categories ? settings.categories : [NSSet set];
    NSSet *myCategories = self.categories ? self.categories : [NSSet set];

    return [otherCategories isSubsetOfSet:myCategories];
}

- (UIUserNotificationSettings *)settingsByMerging:(UIUserNotificationSettings *)settings;
{
    UIUserNotificationType mergedTypes = settings.types & self.types;

    NSSet *myCategories = self.categories ? self.categories : [NSSet set];

    NSMutableDictionary *existingCategoriesByIdentifier = [NSMutableDictionary sequence:myCategories keyMapper:^id(id obj) {
        UIUserNotificationCategory *type = obj;
        return type.identifier;
    }];

    NSSet *newCategories = settings.categories ? settings.categories : [NSSet set];
    NSMutableDictionary *newCategoriesByIdentifier = [NSMutableDictionary sequence:newCategories keyMapper:^id(id obj) {
        UIUserNotificationCategory *type = obj;
        return type.identifier;
    }];

    [newCategoriesByIdentifier enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        existingCategoriesByIdentifier[key] = obj;
    }];

    NSSet *mergedCategories = [NSSet setWithArray:existingCategoriesByIdentifier.allValues];
    return [UIUserNotificationSettings settingsForTypes:mergedTypes categories:mergedCategories];
}

@end

#endif