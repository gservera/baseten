//
// BXDatabaseContextPrivate.h
// BaseTen
//
// Copyright 2008-2010 Marko Karppinen & Co. LLC.
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

#import <BaseTen/BaseTen.h>


struct update_kvo_ctx
{
	__strong NSDictionary*	ukc_rels_by_entity;
	__strong NSArray*		ukc_objects;
	__strong NSDictionary*	ukc_old_targets_by_object;
	__strong NSDictionary*	ukc_new_targets_by_object;
};


@interface BXDatabaseContext (PrivateMethods)
/* Moved from the context. */
- (BOOL) executeDeleteFromEntity: (BXEntityDescription *) anEntity withPredicate: (NSPredicate *) predicate 
                           error: (NSError **) error;

/* Especially these need some attention before moving to a public header. */
- (void) lockObject: (BXDatabaseObject *) object key: (id) key status: (enum BXObjectLockStatus) status
             sender: (id <BXObjectAsynchronousLocking>) sender;
- (void) unlockObject: (BXDatabaseObject *) anObject key: (id) aKey;

/* Really internal. */
+ (void) loadedAppKitFramework;
- (id <BXDatabaseContextDelegate>) internalDelegate;
- (id) executeFetchForEntity: (BXEntityDescription *) entity 
               withPredicate: (NSPredicate *) predicate 
             returningFaults: (BOOL) returnFaults 
             excludingFields: (NSArray *) excludedFields 
               returnedClass: (Class) returnedClass 
                       error: (NSError **) error;
- (NSArray *) executeUpdateObject: (BXDatabaseObject *) anObject entity: (BXEntityDescription *) anEntity 
                        predicate: (NSPredicate *) predicate withDictionary: (NSDictionary *) aDict 
                            error: (NSError **) error;
- (NSArray *) executeDeleteObject: (BXDatabaseObject *) anObject 
                           entity: (BXEntityDescription *) entity
                        predicate: (NSPredicate *) predicate
                            error: (NSError **) error;
- (BOOL) checkDatabaseURI: (NSError **) error;
- (BOOL) checkURIScheme: (NSURL *) url error: (NSError **) error;
- (id <BXInterface>) databaseInterface;
- (void) lazyInit;
- (void) setDatabaseURIInternal: (NSURL *) uri;
- (void) BXDatabaseObjectWillDealloc: (BXDatabaseObject *) anObject;
- (BOOL) registerObject: (BXDatabaseObject *) anObject;
- (void) unregisterObject: (BXDatabaseObject *) anObject;
- (void) setConnectionSetupManager: (id <BXConnector>) anObject;
- (void) faultKeys: (NSArray *) keys inObjectsWithIDs: (NSArray *) ids;
- (void) setCanConnect: (BOOL) aBool;
- (BOOL) checkErrorHandling;
- (void) setLastConnectionError: (NSError *) anError;

- (void) setDatabaseObjectModel: (BXDatabaseObjectModel *) model;
- (void) setDatabaseInterface: (id <BXInterface>) interface;

- (struct update_kvo_ctx) handleWillChangeForUpdate: (NSArray *) objects newValues: (NSDictionary *) newValues;
- (void) handleDidChangeForUpdate: (struct update_kvo_ctx *) ctx newValues: (NSDictionary *) newValues 
				sendNotifications: (BOOL) shouldSend targetEntity: (BXEntityDescription *) entity;
- (void) handleError: (NSError *) error outError: (NSError **) outError;
@end


@interface BXDatabaseContext (Undoing)
- (void) undoGroupWillClose: (NSNotification *) notification;
- (BOOL) prepareSavepointIfNeeded: (NSError **) error;
- (void) undoWithRedoInvocations: (NSArray *) invocations;
- (void) redoInvocations: (NSArray *) invocations;
- (void) rollbackToLastSavepoint;
//- (void) reregisterObjects: (NSArray *) objectIDs values: (NSDictionary *) pkeyValues;
- (void) undoUpdateObjects: (NSArray *) objectIDs 
					oldIDs: (NSArray *) oldIDs 
				attributes: (NSArray *) updatedAttributes
		  createdSavepoint: (BOOL) createdSavepoint 
			   updatedPkey: (BOOL) updatedPkey 
				   oldPkey: (NSDictionary *) oldPkey
		   redoInvocations: (NSArray *) redoInvocations;
@end


@interface BXDatabaseContext (Keychain)
- (NSArray *) keychainItems;
- (SecKeychainItemRef) newestKeychainItem;
- (BOOL) fetchPasswordFromKeychain;
- (void) setKeychainPasswordItem: (SecKeychainItemRef) anItem;
@end


@interface BXDatabaseContext (Callbacks)
- (void) connectionSetupManagerFinishedAttempt;
@end
