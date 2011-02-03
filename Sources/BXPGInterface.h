//
// BXPGInterface.h
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
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXInterface.h>
#import <BaseTen/PGTSQuery.h>


@class BXPGTransactionHandler;
@class BXPGNotificationHandler;
@class BXPGDatabaseDescription;
@class BXPGQueryBuilder;
@class PGTSConnection;
@class BXPGTableDescription;
@class PGTSColumnDescription;
@class PGTSQuery;
@class PGTSResultSet;
@protocol BXPGResultSetPlaceholder;



BX_EXPORT NSString* BXPGReturnList (NSArray* attrs, NSString* alias, BOOL prependAlias);


@interface BXPGVersion : NSObject
{
}
+ (NSNumber *) currentVersionNumber;
+ (NSNumber *) currentCompatibilityVersionNumber;
@end



@interface BXPGInterface : NSObject <BXInterface> 
{
    BXDatabaseContext* mContext; //Weak
	BXPGTransactionHandler* mTransactionHandler;
	BXPGQueryBuilder* mQueryBuilder;
	
	//FIXME: this is a bit of a hack.
	BXEntityDescription* mCurrentlyChangedEntity;
	
	NSMutableSet* mLockedObjects;
	BOOL mLocking;
}

- (BXEntityDescription *) currentlyChangedEntity;
- (void) setCurrentlyChangedEntity: (BXEntityDescription *) entity;

- (BXPGTableDescription *) tableForEntity: (BXEntityDescription *) entity;
- (BXPGTableDescription *) tableForEntity: (BXEntityDescription *) entity 
							   inDatabase: (BXPGDatabaseDescription *) database;

- (BXDatabaseContext *) databaseContext;
- (void) setTransactionHandler: (BXPGTransactionHandler *) handler;
- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) predicate 
					returningFaults: (BOOL) returnFaults class: (Class) aClass forUpdate: (BOOL) forUpdate error: (NSError **) error;
- (NSArray *) observedOids;
- (NSArray *) observedRelids;
- (NSString *) insertQuery: (BXEntityDescription *) entity fieldValues: (NSDictionary *) fieldValues error: (NSError **) error;

- (NSString *) viewDefaultValue: (BXAttributeDescription *) attr error: (NSError **) error;
- (NSString *) recursiveDefaultValue: (NSString *) name entity: (BXEntityDescription *) entity error: (NSError **) error;

- (void) prepareForConnecting;
- (BXPGTransactionHandler *) transactionHandler;

- (void) begunForLocking: (id <BXPGResultSetPlaceholder>) placeholderResult;
- (void) lockedRow: (PGTSResultSet *) res;

//Some of the methods needed by BaseTen Assistant.
- (BOOL) process: (BOOL) shouldAdd primaryKeyFields: (NSArray *) attributeArray error: (NSError **) outError;
- (BOOL) process: (BOOL) shouldEnable entities: (NSArray *) entityArray error: (NSError **) outError;
- (BOOL) removePrimaryKeyForEntity: (BXEntityDescription *) viewEntity error: (NSError **) outError;

- (BOOL) hasBaseTenSchema;
- (NSNumber *) schemaVersion;
- (NSNumber *) schemaCompatibilityVersion;
- (NSNumber *) frameworkCompatibilityVersion;
- (BOOL) checkSchemaCompatibility: (NSError **) error;
@end


@interface BXPGInterface (ConnectionDelegate)
- (void) connectionSucceeded;
- (void) connectionFailed: (NSError *) error;
- (void) connectionLost: (BXPGTransactionHandler *) handler error: (NSError *) error;

- (FILE *) traceFile;
- (void) connection: (PGTSConnection *) connection sentQueryString: (const char *) queryString;
- (void) connection: (PGTSConnection *) connection sentQuery: (PGTSQuery *) query;
- (void) connection: (PGTSConnection *) connection receivedResultSet: (PGTSResultSet *) res;
@end


@interface BXPGInterface (Visitor) <PGTSQueryVisitor>
@end
