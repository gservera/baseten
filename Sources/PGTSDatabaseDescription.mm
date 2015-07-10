//
// PGTSDatabaseDescription.mm
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


#import "PGTSDatabaseDescription.h"
#import "PGTSAbstractDescription.h"
#import "PGTSAbstractObjectDescription.h"
#import "PGTSTableDescription.h"
#import "PGTSSchemaDescription.h"
#import "PGTSTypeDescription.h"
#import "PGTSRoleDescription.h"
#import "BXCollectionFunctions.h"
#import "BXLogger.h"
#import "BXArraySize.h"
#import "BXCollectionFunctions.h"


using namespace BaseTen;


static NSArray*
FindUsingOidVector (const Oid* oidVector, NSDictionary *dict)
{
	NSMutableArray* retval = [NSMutableArray array];
	for (unsigned int i = 0; InvalidOid != oidVector [i]; i++)
	{
		id type = FindObject (dict, oidVector [i]);
		if (type)
			[retval addObject: type];
	}
	return [[retval copy] autorelease];
}


/** 
 * \internal
 * \brief Database.
 */
@implementation PGTSDatabaseDescription
+ (BOOL) accessInstanceVariablesDirectly
{
    return NO;
}

/**
 * \internal
 * \brief Retain on copy.
 */
- (id) copyWithZone: (NSZone *) zone
{
    return [self retain];
}

- (void) dealloc
{
	[mSchemasByOid release];
	[mTablesByOid release];
	[mTypesByOid release];
	[mRolesByOid release];
	[mSchemasByName release];
	[mRolesByName release];	
	[super dealloc];
}


- (PGTSSchemaDescription *) schemaWithOid: (Oid) oid
{
	return FindObject (mSchemasByOid, oid);
}


- (PGTSTypeDescription *) typeWithOid: (Oid) oid
{
	return FindObject (mTypesByOid, oid);
}


- (id) tableWithOid: (Oid) oid
{
	return FindObject (mTablesByOid, oid);
}


- (PGTSRoleDescription *) roleWithOid: (Oid) oid
{
	return FindObject (mRolesByOid, oid);
}


- (PGTSSchemaDescription *) schemaNamed: (NSString *) name
{
	Expect (name);
	return [mSchemasByName objectForKey: name];
}


- (NSDictionary *) schemasByName
{
	return [[mSchemasByName retain] autorelease];
}


- (PGTSRoleDescription *) roleNamed: (NSString *) name
{
	Expect (name);
	return [mRolesByName objectForKey: name];
}


- (NSArray *) typesWithOids: (const Oid *) oidVector
{
	Expect (oidVector);
	return FindUsingOidVector (oidVector, mTypesByOid);
}


- (NSArray *) tablesWithOids: (const Oid *) oidVector
{
	Expect (oidVector);
	return FindUsingOidVector (oidVector, mTablesByOid);
}


- (id) table: (NSString *) tableName inSchema: (NSString *) schemaName
{
	Expect (tableName);
	Expect (schemaName);
		
	return [[self schemaNamed: schemaName] tableNamed: tableName];
}


- (void) setSchemas: (id <NSFastEnumeration>) schemas
{
	NSMutableDictionary *schemasByName = [NSMutableDictionary dictionary];
	NSMutableDictionary *tablesByOid = [NSMutableDictionary dictionary];
	
	for (PGTSSchemaDescription *schema in schemas)
	{
		NSString *name = [schema name];
		if ([name length])
		{
			Insert (schemasByName, [schema name], schema);
		
			for (PGTSTableDescription *table in [schema allTables])
				Insert (tablesByOid, [table oid], table);
		}
	}
	
	[mSchemasByName release];
	[mTablesByOid release];
	mSchemasByName = [schemasByName copy];
	mTablesByOid = [tablesByOid copy];
}


- (void) setTypes: (id <NSFastEnumeration>) types
{
	NSMutableDictionary *typesByOid = [NSMutableDictionary dictionary];
	for (PGTSTypeDescription *typeDesc in types)
		Insert (typesByOid, [typeDesc oid], typeDesc);
	
	[mTypesByOid release];
	mTypesByOid = [typesByOid copy];
}


- (void) setRoles: (id <NSFastEnumeration>) roles
{
	NSMutableDictionary *rolesByName = [NSMutableDictionary dictionary];
	NSMutableDictionary *rolesByOid = [NSMutableDictionary dictionary];
	
	for (PGTSRoleDescription *role in roles)
	{
		Insert (rolesByName, [role name], role);
		Insert (rolesByOid, [role oid], role);
	}
	
	[mRolesByName release];
	[mRolesByOid release];
	mRolesByName = [rolesByName copy];
	mRolesByOid = [rolesByOid copy];
}
@end
