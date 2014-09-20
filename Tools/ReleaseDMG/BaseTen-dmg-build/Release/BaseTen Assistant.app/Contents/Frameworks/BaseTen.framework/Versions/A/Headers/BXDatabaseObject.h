//
// BXDatabaseObject.h
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
@class BXDatabaseObject;
@class BXDatabaseObjectID;
@class BXEntityDescription;
@class BXRelationshipDescription;
@class BXAttributeDescription;


typedef NS_ENUM(int, BXObjectDeletionStatus) {
	kBXObjectExists = 0,
	kBXObjectDeletePending,
	kBXObjectDeleted
};

typedef NS_ENUM(int, BXObjectLockStatus) {
	kBXObjectNoLockStatus = 0,
	kBXObjectLockedStatus,
	kBXObjectDeletedStatus
};


@protocol BXObjectStatusInfo <NSObject>
- (BXDatabaseObjectID *) objectID;
- (NSNumber *) unlocked; //Returns a boolean
- (BOOL) isLockedForKey: (NSString *) aKey;
- (BOOL) isDeleted;
- (void) faultKey: (NSString *) aKey;
- (id) valueForKey: (NSString *) aKey;
- (void) addObserver: (NSObject *) anObserver forKeyPath: (NSString *) keyPath 
             options: (NSKeyValueObservingOptions) options context: (void *) context;
@end

/** 
 * \internal
 * A protocol for performing a callback during a status change. 
 */
@protocol BXObjectAsynchronousLocking <NSObject>
/**
 * Callback for acquiring a lock in the database.
 * \param   lockAcquired        A boolean indicating whether the operation was
 *                              successful or not
 * \param   receiver            The target object
 */
- (void) BXLockAcquired: (BOOL) lockAcquired object: (BXDatabaseObject *) receiver error: (NSError *) error;
@end


@interface BXDatabaseObject : NSObject <NSCopying>
{
    BXDatabaseContext*			mContext; //Weak
    BXDatabaseObjectID*			mObjectID;
    NSMutableDictionary*		mValues;
    BXObjectDeletionStatus      mDeleted;
    BXObjectLockStatus          mLocked;
	BOOL						mCreatedInCurrentTransaction;
	BOOL						mNeedsToAwake;
}

- (BXEntityDescription *) entity;
- (BXDatabaseObjectID *) objectID;
- (BXDatabaseContext *) databaseContext;
- (NSPredicate *) predicate;

- (id) objectForKey: (BXAttributeDescription *) aKey;
- (NSArray *) valuesForKeys: (NSArray *) keys;
- (NSArray *) objectsForKeys: (NSArray *) keys;
- (NSDictionary *) cachedObjects;

- (id <BXObjectStatusInfo>) statusInfo;
- (BOOL) isDeleted;
- (BOOL) isInserted;

- (id) primitiveValueForKey: (NSString *) aKey;
- (void) setPrimitiveValue: (id) aVal forKey: (NSString *) aKey;
- (void) setPrimitiveValuesForKeysWithDictionary: (NSDictionary *) aDict;

- (NSDictionary *) cachedValues;
- (id) cachedValueForKey: (NSString *) aKey;

- (BOOL) isLockedForKey: (NSString *) aKey;

- (void) faultKey: (NSString *) aKey;
- (int) isFaultKey: (NSString *) aKey;

- (BOOL) validateValue: (id *) ioValue forKey: (NSString *) key error: (NSError **) outError;
- (BOOL) validateForDelete: (NSError **) outError;
@end


@interface BXDatabaseObject (Subclassing)
- (id) init;

- (void) awakeFromFetch;
- (void) awakeFromInsert;
- (void) didTurnIntoFault;
@end
