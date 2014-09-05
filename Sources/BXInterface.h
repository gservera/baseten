//
// BXInterface.h
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

#import <Foundation/Foundation.h>
#import <BaseTen/BXDatabaseContext.h>
#import <Security/Security.h>
#import <BaseTen/BXDatabaseObject.h>

@protocol BXObjectAsynchronousLocking;
@class BXDatabaseContext;
@class BXDatabaseObject;
@class BXDatabaseObjectID;
@class BXEntityDescription;


struct BXTrustResult
{
	SecTrustRef trust;
	SecTrustResultType result;
};


@interface BXDatabaseContext (DBInterfaces)
- (BOOL) connectedToDatabase: (BOOL) connected async: (BOOL) async error: (NSError **) error;
- (void) connectionLost: (NSError *) error;
- (void) changedEntity: (BXEntityDescription *) entity;
- (void) addedObjectsToDatabase: (NSArray *) objectIDs;
- (void) updatedObjectsInDatabase: (NSArray *) objectIDs attributes: (NSArray *) changedAttributes faultObjects: (BOOL) shouldFault;
- (void) deletedObjectsFromDatabase: (NSArray *) objectIDs;
- (void) lockedObjectsInDatabase: (NSArray *) objectIDs status: (BXObjectLockStatus) status;
- (void) unlockedObjectsInDatabase: (NSArray *) objectIDs;
- (void) handleInvalidCopiedTrustAsync: (NSValue *) value;
- (BOOL) handleInvalidTrust: (SecTrustRef) trust result: (SecTrustResultType) result;
- (NSError *) packQueryError: (NSError *) error;
- (enum BXSSLMode) sslMode;
- (void) networkStatusChanged: (SCNetworkConnectionFlags) newFlags;
@end


/**
 * \internal
 * BXInterface.
 * Formal part of the protocol
 */
@protocol BXInterface <NSObject>

- (id) initWithContext: (BXDatabaseContext *) aContext;

- (BOOL) logsQueries;
- (void) setLogsQueries: (BOOL) shouldLog;

/** 
 * \internal
 * \name Queries 
 */
//@{
- (id) createObjectForEntity: (BXEntityDescription *) entity withFieldValues: (NSDictionary *) fieldValues
                       class: (Class) aClass error: (NSError **) error;
- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) predicate 
					returningFaults: (BOOL) returnFaults class: (Class) aClass error: (NSError **) error;
- (BOOL) fireFault: (BXDatabaseObject *) anObject keys: (NSArray *) keys error: (NSError **) error;
- (NSArray *) executeUpdateWithDictionary: (NSDictionary *) aDict
                                 objectID: (BXDatabaseObjectID *) anID
                                   entity: (BXEntityDescription *) entity
                                predicate: (NSPredicate *) predicate
                                    error: (NSError **) error;
- (NSArray *) executeDeleteObjectWithID: (BXDatabaseObjectID *) objectID 
                                 entity: (BXEntityDescription *) entity 
                              predicate: (NSPredicate *) predicate 
                                  error: (NSError **) error;
- (NSArray *) executeQuery: (NSString *) queryString parameters: (NSArray *) parameters error: (NSError **) error;
- (unsigned long long) executeCommand: (NSString *) commandString error: (NSError **) error;

/** 
 * \internal
 * Lock an object asynchronously.
 */
- (void) lockObject: (BXDatabaseObject *) object key: (id) key lockType: (BXObjectLockStatus) type
             sender: (id <BXObjectAsynchronousLocking>) sender;
/**
 * \internal
 * Unlock a locked object synchronously.
 */
- (void) unlockObject: (BXDatabaseObject *) anObject key: (id) aKey;
//@}

- (BOOL) connected;

/** 
 * \internal
 * \name Connecting to the database 
 */
//@{
- (BOOL) connectSync: (NSError **) error;
- (void) connectAsync;
- (void) disconnect;
//@}

#if 0
- (void) setLogsQueries: (BOOL) aBool;
- (BOOL) logsQueries;
#endif

/**
 * \internal
 * \name Transactions 
 */
//@{
- (void) rollback;
- (BOOL) save: (NSError **) error;

- (void) setAutocommits: (BOOL) aBool;
- (BOOL) autocommits;

- (BOOL) rollbackToLastSavepoint: (NSError **) error;
- (BOOL) establishSavepoint: (NSError **) error;
//@}

- (void) handledTrust: (SecTrustRef) trust accepted: (BOOL) accepted;
- (BOOL) isSSLInUse;
- (NSNumber *) defaultPort;
- (BOOL) usedPassword;

- (void) reloadDatabaseMetadata;
- (void) prepareForEntityValidation;
- (BOOL) validateEntities: (NSArray *) entities error: (NSError **) outError;
- (BOOL) observeEntity: (BXEntityDescription *) entity 
			   options: (enum BXObservingOption) options 
				 error: (NSError **) error;
@end
