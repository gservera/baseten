
@import BaseTen;


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
