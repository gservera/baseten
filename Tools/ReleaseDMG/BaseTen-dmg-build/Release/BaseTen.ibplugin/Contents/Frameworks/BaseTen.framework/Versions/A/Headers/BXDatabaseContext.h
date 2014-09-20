//
// BXDatabaseContext.h
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
#import <Security/Security.h>
#import <BaseTen/BXConstants.h>
#import <BaseTen/BXDatabaseContextDelegateProtocol.h>

#ifndef IBAction
#define IBAction void
#endif

#ifndef IBOutlet
#define IBOutlet
#endif

//Hide from Interface Builder
#define BXHiddenId id


#if defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE
#define SecKeychainItemRef void*
#endif


@class NSWindow;


@protocol BXInterface;
@protocol BXObjectAsynchronousLocking;
@protocol BXConnector;
@class BXDatabaseObject;
@class BXEntityDescription;
@class BXDatabaseObjectID;
@class BXDatabaseObjectModel;
@class BXDatabaseObjectModelStorage;
@class NSEntityDescription;


@interface BXDatabaseContext : NSObject
{
    BXHiddenId <BXInterface>				mDatabaseInterface;
    NSURL*									mDatabaseURI;
    id										mObjects;
    NSMutableDictionary*                    mModifiedObjectIDs;
    NSUndoManager*							mUndoManager;
	NSMutableIndexSet*						mUndoGroupingLevels;
	BXHiddenId <BXConnector>				mConnectionSetupManager;
	BXDatabaseObjectModel*					mObjectModel;
	BXDatabaseObjectModelStorage*			mObjectModelStorage;
	
    SecKeychainItemRef                      mKeychainPasswordItem;
    NSNotificationCenter*                   mNotificationCenter;
	id <BXDatabaseContextDelegate>			mDelegateProxy;
	NSError*								mLastConnectionError;
	
	IBOutlet NSWindow*						modalWindow; /**< \brief An NSWindow to which sheets are attached. \see -modalWindow */
	IBOutlet id	<BXDatabaseContextDelegate>	delegate; 	/**< \brief The context's delegate. \see -delegate */
	
	enum BXConnectionErrorHandlingState		mConnectionErrorHandlingState;

    BOOL									mAutocommits;
    BOOL									mDeallocating;
	BOOL									mDisplayingSheet;
	BOOL									mRetryingConnection;
    BOOL									mRetainRegisteredObjects;
	BOOL									mUsesKeychain;
	BOOL									mShouldStoreURICredentials;
	BOOL									mCanConnect;
	BOOL									mDidDisconnect;
	BOOL									mConnectsOnAwake;
	BOOL									mSendsLockQueries;
}

+ (BOOL) setInterfaceClass: (Class) aClass forScheme: (NSString *) scheme;
+ (Class) interfaceClassForScheme: (NSString *) scheme;

+ (id) contextWithDatabaseURI: (NSURL *) uri;
- (id) initWithDatabaseURI: (NSURL *) uri;
- (void) setDatabaseURI: (NSURL *) uri;
- (NSURL *) databaseURI;
- (BOOL) isConnected;

- (BXDatabaseObjectModel *) databaseObjectModel;

- (BOOL) retainsRegisteredObjects;
- (void) setRetainsRegisteredObjects: (BOOL) flag;

- (void) setAutocommits: (BOOL) flag;
- (BOOL) autocommits;
- (void) rollback;
- (BOOL) save: (NSError **) error;

- (BOOL) connectSync: (NSError **) error;
- (void) connectAsync;
- (void) disconnect;

- (BOOL) connectIfNeeded: (NSError **) error;

- (NSArray *) faultsWithIDs: (NSArray *) anArray;
- (BXDatabaseObject *) registeredObjectWithID: (BXDatabaseObjectID *) objectID;
- (NSArray *) registeredObjectsWithIDs: (NSArray *) objectIDs;
- (NSArray *) registeredObjectsWithIDs: (NSArray *) objectIDs nullObjects: (BOOL) returnNullObjects;

- (NSUndoManager *) undoManager;
- (BOOL) setUndoManager: (NSUndoManager *) aManager;

- (NSWindow *) modalWindow;
- (void) setModalWindow: (NSWindow *) aWindow;
- (id <BXDatabaseContextDelegate>) delegate;
- (void) setDelegate: (id <BXDatabaseContextDelegate>) anObject;

- (BOOL) usesKeychain;
- (void) setUsesKeychain: (BOOL) usesKeychain;
- (BOOL) storesURICredentials;
- (void) setStoresURICredentials: (BOOL) shouldStore;

- (BOOL) canConnect;

- (void) setConnectsOnAwake: (BOOL) flag;
- (BOOL) connectsOnAwake;

- (void) setSendsLockQueries: (BOOL) flag;
- (BOOL) sendsLockQueries;

- (void) refreshObject: (BXDatabaseObject *) object mergeChanges: (BOOL) flag;

- (NSNotificationCenter *) notificationCenter;

- (void) setAllowReconnecting: (BOOL) shouldAllow;
- (BOOL) isSSLInUse;

- (BOOL) logsQueries;
- (void) setLogsQueries: (BOOL) shouldLog;

- (BXDatabaseObjectModelStorage *) databaseObjectModelStorage;
- (void) setDatabaseObjectModelStorage: (BXDatabaseObjectModelStorage *) storage;
@end


@interface BXDatabaseContext (Queries)
- (id) objectWithID: (BXDatabaseObjectID *) anID error: (NSError **) error;
- (NSSet *) objectsWithIDs: (NSArray *) anArray error: (NSError **) error;

- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) 
                    predicate error: (NSError **) error;
- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) predicate 
                    returningFaults: (BOOL) returnFaults error: (NSError **) error;
- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) predicate 
                    excludingFields: (NSArray *) excludedFields error: (NSError **) error;
- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) predicate 
                    returningFaults: (BOOL) returnFaults updateAutomatically: (BOOL) shouldUpdate error: (NSError **) error;
- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) predicate 
                    excludingFields: (NSArray *) excludedFields updateAutomatically: (BOOL) shouldUpdate error: (NSError **) error;

- (id) createObjectForEntity: (BXEntityDescription *) entity withFieldValues: (NSDictionary *) fieldValues error: (NSError **) error;

- (BOOL) executeDeleteObject: (BXDatabaseObject *) anObject error: (NSError **) error;

- (BOOL) fireFault: (BXDatabaseObject *) anObject key: (id) aKey error: (NSError **) error;

- (BOOL) observeEntity: (BXEntityDescription *) entity options: (enum BXObservingOption) options error: (NSError **) error;

/* These methods should only be used for purposes which the ones above are not suited. */
- (NSArray *) executeQuery: (NSString *) queryString error: (NSError **) error;
- (NSArray *) executeQuery: (NSString *) queryString parameters: (NSArray *) parameters error: (NSError **) error;
- (unsigned long long) executeCommand: (NSString *) commandString error: (NSError **) error;
@end


@interface BXDatabaseContext (HelperMethods)
- (NSArray *) objectIDsForEntity: (BXEntityDescription *) anEntity error: (NSError **) error;
- (NSArray *) objectIDsForEntity: (BXEntityDescription *) anEntity predicate: (NSPredicate *) predicate error: (NSError **) error;

- (BOOL) canGiveEntities BX_DEPRECATED_IN_1_8;
- (BXEntityDescription *) entityForTable: (NSString *) tableName inSchema: (NSString *) schemaName error: (NSError **) error BX_DEPRECATED_IN_1_8;
- (BXEntityDescription *) entityForTable: (NSString *) tableName error: (NSError **) error BX_DEPRECATED_IN_1_8;
- (NSDictionary *) entitiesBySchemaAndName: (BOOL) reload error: (NSError **) error BX_DEPRECATED_IN_1_8;

- (BOOL) entity: (NSEntityDescription *) entity existsInSchema: (NSString *) schemaName error: (NSError **) error BX_DEPRECATED_IN_1_8;
- (BXEntityDescription *) matchingEntity: (NSEntityDescription *) entity inSchema: (NSString *) schemaName error: (NSError **) error BX_DEPRECATED_IN_1_8;
@end


@interface BXDatabaseContext (NSCoding) <NSCoding> 
/* Only basic support for Interface Builder. */
@end


@interface BXDatabaseContext (IBActions)
- (IBAction) saveDocument: (id) sender;
- (IBAction) revertDocumentToSaved: (id) sender;
- (IBAction) connect: (id) sender;
@end
