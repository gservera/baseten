//
// PGTSMetadataContainer.h
// BaseTen
//
// Copyright 2009-2010 Marko Karppinen & Co. LLC.
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
#import <PGTSOids.h>


@class PGTSDatabaseDescription;
@class PGTSConnection;
@class PGTSMetadataStorage;
@class PGTSSchemaDescription;
@class PGTSTableDescription;
@class PGTSIndexDescription;


@interface PGTSMetadataContainerLoadState : NSObject
{
	NSMutableDictionary *mSchemasByOid;
	NSMutableDictionary *mTablesByOid;
	NSMutableDictionary *mIndexesByRelid;
}
- (PGTSSchemaDescription *) schemaWithOid: (Oid) oid;
- (PGTSTableDescription *) tableWithOid: (Oid) oid;
- (PGTSTableDescription *) tableWithOid: (Oid) oid descriptionClass: (Class) descriptionClass;
- (PGTSIndexDescription *) addIndexForRelation: (Oid) relid;

- (void) assignSchemas: (PGTSDatabaseDescription *) database;
- (void) assignUniqueIndexes: (PGTSDatabaseDescription *) database;
@end



@interface PGTSMetadataContainer : NSObject
{
	PGTSMetadataStorage* mStorage;
	NSURL* mStorageKey;
	id mDatabase;
}
- (id) initWithStorage: (PGTSMetadataStorage *) mStorage key: (NSURL *) key;
- (id) databaseDescription;
- (void) prepareForConnection: (PGTSConnection *) connection;
- (void) reloadUsingConnection: (PGTSConnection *) connection;
- (Class) loadStateClass;
- (Class) databaseDescriptionClass;
- (Class) tableDescriptionClass;
@end


@interface PGTSEFMetadataContainer : PGTSMetadataContainer
{
}
- (void) loadUsing: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState;
- (void) loadUsing: (PGTSConnection *) connection;
@end
