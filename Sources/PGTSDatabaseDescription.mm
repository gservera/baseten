//
// PGTSDatabaseDescription.mm
// BaseTen
//
// Copyright (C) 2006-2009 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://www.karppinen.fi/baseten/licensing/ or by contacting
// us at sales@karppinen.fi. Without an additional license, this software
// may be distributed only in compliance with the GNU General Public License.
//
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License, version 2.0,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
// $Id$
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
