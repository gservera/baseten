//
// BXObjectStatusToColorTransformer.m
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

#import "BXObjectStatusToColorTransformer.h"
#import <BaseTen/BXDatabaseObject.h>

@implementation BXObjectStatusToColorTransformer

+ (Class)transformedValueClass {
    return [NSColor class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(NSValue *)objectStatus {
    id retval = nil;
    enum BXObjectLockStatus status = kBXObjectNoLockStatus;
    [objectStatus getValue: &status];
    
    switch (status) {
        case kBXObjectLockedStatus:
            retval = [NSColor grayColor];
            break;
        case kBXObjectDeletedStatus:
            retval = [NSColor redColor];
            break;
        case kBXObjectNoLockStatus:
        default:
            retval = [NSColor blackColor];
    }
    return retval;
}

@end
