//
// PGTSDatabaseDescription.h
// BaseTen
//
// Copyright 2006-2010 Marko Karppinen & Co. LLC.
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
#import <BaseTen/libpq-fe.h>
#import <BaseTen/PGTSAbstractDescription.h>

@class PGTSSchemaDescription;
@class PGTSTableDescription;
@class PGTSTypeDescription;
@class PGTSRoleDescription;
@class PGTSResultSet;


@interface PGTSDatabaseDescription : NSObject <NSCopying>
{
	NSDictionary *mSchemasByOid;
	NSDictionary *mTablesByOid;
	NSDictionary *mTypesByOid;
	NSDictionary *mRolesByOid;	
	NSDictionary *mSchemasByName;
	NSDictionary *mRolesByName;
}
- (PGTSSchemaDescription *) schemaWithOid: (Oid) anOid;
- (PGTSSchemaDescription *) schemaNamed: (NSString *) name;
- (NSDictionary *) schemasByName;

- (PGTSTypeDescription *) typeWithOid: (Oid) anOid;
- (NSArray *) typesWithOids: (const Oid *) oidVector;

- (id) tableWithOid: (Oid) anOid;
- (NSArray *) tablesWithOids: (const Oid *) oidVector;
- (id) table: (NSString *) tableName inSchema: (NSString *) schemaName;

- (PGTSRoleDescription *) roleWithOid: (Oid) anOid;
- (PGTSRoleDescription *) roleNamed: (NSString *) name;


//Thread un-safe methods.
- (void) setSchemas: (id <NSFastEnumeration>) schemas;
- (void) setTypes: (id <NSFastEnumeration>) types;
- (void) setRoles: (id <NSFastEnumeration>) roles;
@end
