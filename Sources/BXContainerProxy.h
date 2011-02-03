//
// BXContainerProxy.h
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

#import <Foundation/Foundation.h>

@class BXDatabaseContext;
@class BXEntityDescription;
@class BXDatabaseObject;

@interface BXContainerProxy : NSProxy <NSCopying>
{
    BXDatabaseContext* mContext;
    id mContainer;
    id mOwner;
    NSString* mKey;
    Class mNonMutatingClass;
    NSPredicate* mFilterPredicate;
    BXEntityDescription* mEntity;
    BOOL mIsMutable;
    BOOL mChanging;
}

- (id) BXInitWithArray: (NSMutableArray *) anArray;
- (void) filterObjectsForUpdate: (NSArray *) objects 
                          added: (NSMutableArray **) added 
                        removed: (NSMutableArray **) removed;
- (NSMutableDictionary *) substitutionVariables;
@end


@interface BXContainerProxy (Accessors)
- (BXDatabaseContext *) context;
- (void) setDatabaseContext: (BXDatabaseContext *) aContext;
- (NSPredicate *) filterPredicate;
- (void) setFilterPredicate: (NSPredicate *) aPredicate;
- (void) setEntity: (BXEntityDescription *) anEntity;
- (void) fetchedForEntity: (BXEntityDescription *) entity predicate: (NSPredicate *) predicate;
- (id) owner;
- (void) setOwner: (id) anObject;
- (void) setKey: (NSString *) aString;
- (NSString *) key;
@end


@interface BXContainerProxy (Callbacks)
- (void) handleAddedObjects: (NSArray *) objectArray;
- (void) handleRemovedObjects: (NSArray *) objectArray;
- (void) addedObjectsWithIDs: (NSArray *) ids;
- (void) removedObjectsWithIDs: (NSArray *) ids;
- (void) updatedObjectsWithIDs: (NSArray *) ids;
@end


@interface BXContainerProxy (Notifications)
- (void) addedObjects: (NSNotification *) notification;
- (void) deletedObjects: (NSNotification *) notification;
- (void) updatedObjects: (NSNotification *) notification;
@end
