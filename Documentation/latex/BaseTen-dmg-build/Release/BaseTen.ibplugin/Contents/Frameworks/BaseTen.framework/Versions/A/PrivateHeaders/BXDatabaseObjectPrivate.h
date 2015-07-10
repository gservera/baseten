//
// BXDatabaseObjectPrivate.h
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


#import <BaseTen/BXDatabaseObject.h>


@interface BXDatabaseObject (PrivateMethods)
- (BOOL) isCreatedInCurrentTransaction;
- (void) setCreatedInCurrentTransaction: (BOOL) aBool;
- (enum BXObjectDeletionStatus) deletionStatus;
- (void) setDeleted: (enum BXObjectDeletionStatus) status;
- (BOOL) checkNullConstraintForValue: (id *) ioValue key: (NSString *) key error: (NSError **) outError;
- (void) setCachedValue: (id) aValue forKey: (NSString *) aKey;
- (void) setCachedValuesForKeysWithDictionary: (NSDictionary *) aDict;
- (void) setCachedValue2: (id) aValue forKey: (id) aKey;
- (void) BXDatabaseContextWillDealloc;
- (id) valueForUndefinedKey: (NSString *) aKey;
- (void) setValue: (id) aValue forUndefinedKey: (NSString *) aKey;
- (void) lockKey: (id) key status: (enum BXObjectLockStatus) objectStatus sender: (id <BXObjectAsynchronousLocking>) sender;
- (void) lockForDelete;
- (void) clearStatus;
- (void) setLockedForKey: (NSString *) aKey;
- (BOOL) registerWithContext: (BXDatabaseContext *) ctx entity: (BXEntityDescription *) entity;
- (BOOL) registerWithContext: (BXDatabaseContext *) ctx objectID: (BXDatabaseObjectID *) anID;
- (BOOL) lockedForDelete;
- (void) awakeFromFetchIfNeeded;
- (NSArray *) keysIncludedInQuery: (id) aKey;
- (void) awakeFromInsertIfNeeded;
- (enum BXDatabaseObjectKeyType) keyType: (NSString *) aKey;
- (NSDictionary *) primaryKeyFieldValues;
- (NSDictionary *) primaryKeyFieldObjects;
- (NSDictionary *) allValues;
- (void) removeFromCache: (NSString *) aKey postingKVONotifications: (BOOL) posting;
- (id) valueForUndefinedKey2: (NSString *) aKey;

- (NSDictionary *) valuesForRelationships: (id) relationships fireFault: (BOOL) fireFault;
- (void) willChangeInverseToOneRelationships: (id) relationships from: (NSDictionary *) oldTargets to: (NSDictionary *) newTargets;
- (void) didChangeInverseToOneRelationships: (id) relationships from: (NSDictionary *) oldTargets to: (NSDictionary *) newTargets;
@end
