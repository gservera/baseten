//
// BXObjectStatusToEditableTransformer.m
// BaseTen
//
// Copyright 2008-2009 Marko Karppinen & Co. LLC.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "BXObjectStatusToEditableTransformer.h"
#import <BaseTen/BXDatabaseObject.h>

@implementation BXObjectStatusToEditableTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(NSValue *)objectStatus {
    BOOL isEditable = NO;
    enum BXObjectLockStatus status = kBXObjectNoLockStatus;
    [objectStatus getValue:&status];
    switch (status) {
        case kBXObjectNoLockStatus:
            isEditable = YES;
        case kBXObjectLockedStatus:
        case kBXObjectDeletedStatus:
        default:
            break;
    }
    return [NSNumber numberWithBool:isEditable];
}

@end
