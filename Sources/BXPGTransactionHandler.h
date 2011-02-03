//
// BXPGTransactionHandler.h
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
#import <BaseTen/BXConstants.h>
#import <BaseTen/PGTSConnection.h>
#import <BaseTen/BXPGCertificateVerificationDelegate.h>


@class PGTSConnection;
@class BXEntityDescription;
@class BXPGInterface;
@class BXPGDatabaseDescription;
@class BXPGCertificateVerificationDelegate;
@class BXPGQueryBuilder;


BX_EXPORT NSString* kBXPGUserInfoKey;
BX_EXPORT NSString* kBXPGDelegateKey;
BX_EXPORT NSString* kBXPGCallbackSelectorStringKey;


@protocol BXPGResultSetPlaceholder <NSObject>
- (BOOL) querySucceeded;
- (id) userInfo;
- (NSError *) error;
@end



@interface BXPGTransactionHandler : NSObject 
{
	BXPGInterface* mInterface; //Weak.
	BXPGCertificateVerificationDelegate* mCertificateVerificationDelegate;
	PGTSConnection* mConnection;
	
	NSMutableDictionary *mModificationHandlersByEntity;
	NSMutableDictionary* mEntityObserversByNotificationName;
	NSMutableDictionary* mChangeHandlers;
	NSMutableDictionary* mLockHandlers;
	NSMutableDictionary* mDatabaseIdentifiers;
	
	NSUInteger mSavepointIndex;
	NSError** mSyncErrorPtr;
	BOOL mAsync;
	BOOL mConnectionSucceeded;
	
	BOOL mIsResetting;
}
- (PGTSConnection *) connection;
- (BXPGInterface *) interface;
- (void) setInterface: (BXPGInterface *) interface;
- (BOOL) isAsync;
- (BOOL) isSSLInUse;

- (void) connectAsync;
- (BOOL) connectSync: (NSError **) outError;
- (void) disconnect;
- (BOOL) connected;
- (BOOL) usedPassword;

- (BOOL) canSend: (NSError **) outError;

- (NSString *) savepointQuery;
- (NSString *) rollbackToSavepointQuery;
- (void) resetSavepointIndex;
- (NSUInteger) savepointIndex;

- (void) prepareForConnecting;
- (void) didDisconnect;
- (NSDictionary *) connectionDictionary;
- (NSError *) connectionError: (NSError *) error recoveryAttempterClass: (Class) aClass;
- (BXPGDatabaseDescription *) databaseDescription;
- (void) refreshDatabaseDescription;

- (void) handleConnectionErrorFor: (PGTSConnection *) failedConnection;
- (void) handleSuccess;

- (BOOL) observeEntity: (BXEntityDescription *) entity options: (enum BXObservingOption) options error: (NSError **) error;
- (BOOL) observeEntity: (BXEntityDescription *) entity 
			connection: (PGTSConnection *) connection 
			   options: (enum BXObservingOption) options 
				 error: (NSError **) error;
- (BOOL) addClearLocksHandler: (PGTSConnection *) connection error: (NSError **) outError;

- (void) checkSuperEntities: (BXEntityDescription *) entity;
- (void) checkSuperEntities: (BXEntityDescription *) entity connection: (PGTSConnection *) connection;
- (NSArray *) observedOids;
- (NSArray *) observedRelids;

- (BOOL) logsQueries;
- (void) setLogsQueries: (BOOL) shouldLog;

- (void) markLocked: (BXEntityDescription *) entity 
	  relationAlias: (NSString *) alias
		 fromClause: (NSString *) fromClause
		whereClause: (NSString *) whereClause 
		 parameters: (NSArray *) parameters
		 willDelete: (BOOL) willDelete;
- (void) markLocked: (BXEntityDescription *) entity
	  relationAlias: (NSString *) alias
		 fromClause: (NSString *) fromClause
		whereClause: (NSString *) whereClause 
		 parameters: (NSArray *) parameters
		 willDelete: (BOOL) willDelete
		 connection: (PGTSConnection *) connection 
   notifyConnection: (PGTSConnection *) notifyConnection;

- (void) sendPlaceholderResultTo: (id) receiver callback: (SEL) callback 
					   succeeded: (BOOL) didSucceed userInfo: (id) userInfo;
- (void) forwardResult: (id) result;

- (void) reloadDatabaseMetadata;

/**
 * \internal
 * \brief Begins a transaction.
 *
 * Begins a transactions unless there already is one.
 */
- (BOOL) beginIfNeeded: (NSError **) outError;
- (void) beginIfNeededFor: (id) delegate callback: (SEL) callback userInfo: (id) userInfo;

/**
 * \internal
 * \brief Commits the current transaction.
 */
- (BOOL) save: (NSError **) outError;

/**
 * \internal
 * \brief Cancels the current transaction.
 */
- (BOOL) rollback: (NSError **) outError;

/**
 * \internal
 * \brief Creates a savepoint if needed.
 *
 * Use with single queries.
 */
- (BOOL) savepointIfNeeded: (NSError **) outError;

/**
 * \internal
 * \brief Rollback to last savepoint.
 */
- (BOOL) rollbackToLastSavepoint: (NSError **) outError;

/**
 * \internal
 * \brief Creates a savepoint or begins a transaction.
 *
 * Use with multiple queries.
 */
- (BOOL) beginSubTransactionIfNeeded: (NSError **) outError;
- (void) beginAsyncSubTransactionFor: (id) delegate callback: (SEL) callback userInfo: (NSDictionary *) userInfo;

/**
 * \internal
 * \brief Commits a previously begun subtransaction.
 */
- (BOOL) endSubtransactionIfNeeded: (NSError **) outError;

/**
 * \internal
 * \brief Rollback a previously begun subtransaction.
 */
- (void) rollbackSubtransaction;

- (BOOL) autocommits;

@end


@interface BXPGTransactionHandler (PGTSConnectionDelegate) <PGTSConnectionDelegate>
@end


@interface BXPGTransactionHandler (BXPGTrustHandler) <BXPGTrustHandler>
@end
