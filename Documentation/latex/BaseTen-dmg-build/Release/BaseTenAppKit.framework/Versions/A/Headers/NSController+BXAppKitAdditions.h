//
// NSController+BXCocoaAdditions.h
// BaseTen
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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

#import <Cocoa/Cocoa.h>

@protocol BXController;
@protocol BXObjectAsynchronousLocking;
@class BXDatabaseObject;


@interface NSController (BXCocoaAdditions) <BXController, BXObjectAsynchronousLocking>
- (void) BXLockObject: (BXDatabaseObject *) object key: (NSString *) key 
			   status: (BXObjectLockStatus) status editor: (id) editor;
- (void) BXUnlockObject: (BXDatabaseObject *) anObject key: (NSString *) key editor: (id) editor;
@end


@interface NSObjectController (BXCocoaAdditions)
- (void) BXLockKey: (NSString *) key status: (BXObjectLockStatus) status editor: (id) editor;
- (void) BXUnlockKey: (NSString *) key editor: (id) editor;
@end
