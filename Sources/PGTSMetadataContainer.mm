//
// PGTSMetadataContainer.mm
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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


#import "PGTSMetadataContainer.h"
#import "PGTSMetadataStorage.h"
#import "BXLogger.h"
#import "PGTSConnection.h"
#import "PGTSResultSet.h"
#import "PGTSDatabaseDescription.h"
#import "PGTSSchemaDescription.h"
#import "PGTSTypeDescription.h"
#import "PGTSTableDescription.h"
#import "PGTSColumnDescription.h"
#import "PGTSIndexDescription.h"
#import "PGTSRoleDescription.h"
#import "BXEnumerate.h"
#import "PGTSOids.h"
#import "BXCollectionFunctions.h"


using namespace BaseTen;



@implementation PGTSMetadataContainerLoadState
- (id) init
{
	if ((self = [super init]))
	{
		mSchemasByOid = [[NSMutableDictionary alloc] init];
		mTablesByOid = [[NSMutableDictionary alloc] init];
		mIndexesByRelid = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (void) dealloc
{
	[mSchemasByOid release];
	[mTablesByOid release];
	[mIndexesByRelid release];
	[super dealloc];
}


- (PGTSSchemaDescription *) schemaWithOid: (Oid) oid
{
	PGTSSchemaDescription *retval = FindObject (mSchemasByOid, oid);
	if (! retval)
	{
		retval = [[PGTSSchemaDescription alloc] init];
		[retval setOid: oid];
		Insert (mSchemasByOid, oid, retval);
		[retval release];
	}
	return retval;
}


- (PGTSTableDescription *) tableWithOid: (Oid) oid
{
	return FindObject (mTablesByOid, oid);
}


- (PGTSTableDescription *) tableWithOid: (Oid) oid descriptionClass: (Class) descriptionClass
{
	PGTSTableDescription *retval = FindObject (mTablesByOid, oid);
	if (! retval)
	{
		retval = [[descriptionClass alloc] init];
		[retval setOid: oid];
		Insert (mTablesByOid, oid, retval);
        [retval release]; //? added
	}
	return retval;
}


- (PGTSIndexDescription *) addIndexForRelation: (Oid) relid
{	
	PGTSIndexDescription *retval = [[[PGTSIndexDescription alloc] init] autorelease];
	NSMutableArray *indexes = FindObject (mIndexesByRelid, relid);
	if (! indexes)
	{
		indexes = [NSMutableArray array];
		Insert (mIndexesByRelid, relid, indexes);
	}
	[indexes addObject: retval];
	return retval;
}


- (void) assignSchemas: (PGTSDatabaseDescription *) database
{	
	NSMutableDictionary *tablesBySchemaName = [NSMutableDictionary dictionaryWithCapacity: [mSchemasByOid count]];
	for (PGTSTableDescription *table in [mTablesByOid objectEnumerator])
	{
		NSString *schemaName = [table schemaName];
		NSMutableArray *tables = [tablesBySchemaName objectForKey: schemaName];
		if (! tables)
		{
			tables = [NSMutableArray array];
			[tablesBySchemaName setObject: tables forKey: schemaName];
		}
		[tables addObject: table];
	}
	
	for (PGTSSchemaDescription *schema in [mSchemasByOid objectEnumerator])
	{
		NSArray *tables = [tablesBySchemaName objectForKey: [schema name]];
		[schema setTables: tables];
	}
	
	[database setSchemas: [mSchemasByOid objectEnumerator]];
}


- (void) assignUniqueIndexes: (PGTSDatabaseDescription *) database
{
	for (NSNumber *key in mIndexesByRelid)
	{
		PGTSTableDescription *table = [database tableWithOid: [key PGTSOidValue]];
		id indexes = [mIndexesByRelid objectForKey: key];
		[table setUniqueIndexes: indexes];
	}
	
}
@end



@implementation PGTSMetadataContainer
- (id) initWithStorage: (PGTSMetadataStorage *) storage key: (NSURL *) key
{
	if ((self = [super init]))
	{
		mStorage = [storage retain];
		mStorageKey = [key retain];
	}
	return self;
}

- (id) init
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

- (void) dealloc
{
	[mStorage containerWillDeallocate: mStorageKey];
	[mStorage release];
	[mStorageKey release];
	[mDatabase release];
	[super dealloc];
}


- (Class) loadStateClass
{
	return [PGTSMetadataContainerLoadState class];
}


- (Class) databaseDescriptionClass
{
	return [PGTSDatabaseDescription class];
}

- (Class) tableDescriptionClass
{
	return [PGTSTableDescription class];
}

- (id) databaseDescription;
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

- (void) prepareForConnection: (PGTSConnection *) connection;
{
	[self doesNotRecognizeSelector: _cmd];
}

- (void) reloadUsingConnection: (PGTSConnection *) connection
{
	[self doesNotRecognizeSelector: _cmd];
}
@end



@implementation PGTSEFMetadataContainer
//FIXME: come up with a better way to handle query problems than ExpectV.
- (void) fetchTypes: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	ExpectV (connection);
	NSString* query = 
	@"SELECT t.oid, typname, typnamespace, typelem, typdelim, typtype, typlen "
	@" FROM pg_type t ";
	
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded]);
	
	{
		[res setDeterminesFieldClassesAutomatically: NO];
		//Oid is parsed manually.
		[res setClass: [NSString class] forKey: @"typname"];
		[res setClass: [NSNumber class] forKey: @"typnamespace"];
		[res setClass: [NSNumber class] forKey: @"typelem"];
		[res setClass: [NSString class] forKey: @"typdelim"];
		[res setClass: [NSString class] forKey: @"typtype"];
		[res setClass: [NSNumber class] forKey: @"typlen"];
		
		NSMutableArray *types = [NSMutableArray arrayWithCapacity: [res count]];
		
		while ([res advanceRow])
		{
			PGTSTypeDescription* typeDesc = [[[PGTSTypeDescription alloc] init] autorelease];
			
			//Oid needs to be parsed manually to prevent infinite recursion.
			//The type description of Oid might not be cached yet.
			char* oidString = PQgetvalue ([res PGresult], [res currentRow], 0);
			long oid = strtol (oidString, NULL, 10);
			[typeDesc setOid:(Oid)oid];
			
			[typeDesc setName: [res valueForKey: @"typname"]];
			[typeDesc setElementOid: [[res valueForKey: @"typelem"] PGTSOidValue]];
			unichar delimiter = [[res valueForKey: @"typdelim"] characterAtIndex: 0];
			ExpectV (delimiter <= UCHAR_MAX);
			[typeDesc setDelimiter: delimiter];
			unichar kind = [[res valueForKey: @"typtype"] characterAtIndex: 0];
			ExpectV (kind <= UCHAR_MAX);
			[typeDesc setKind: kind];
			NSInteger length = [[res valueForKey: @"typlen"] integerValue];
			[typeDesc setLength: length];
			
			[typeDesc setSchema: [loadState schemaWithOid: [[res valueForKey: @"typnamespace"] PGTSOidValue]]];
			[types addObject: typeDesc];
		}
		
		[mDatabase setTypes: types];
	}
}


- (void) fetchSchemas: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	ExpectV (connection);
	NSString* query = @"SELECT oid, nspname FROM pg_namespace";
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded]);
	
	{
		while ([res advanceRow])
		{
			NSNumber* oid = [res valueForKey: @"oid"];
			PGTSSchemaDescription *schema = [loadState schemaWithOid: [oid PGTSOidValue]];
			[schema setName: [res valueForKey: @"nspname"]];
		}
	}
}


- (void) fetchRoles: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	ExpectV (connection);

	//We could easily fetch login, connection limit etc. privileges here.
	NSString* query =
	@"SELECT oid, rolname "
	@" FROM pg_roles ";
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded]);
	
	{
		NSMutableArray *roles = [NSMutableArray arrayWithCapacity: [res count]];
		
		while ([res advanceRow])
		{
			PGTSRoleDescription* role = [[[PGTSRoleDescription alloc] init] autorelease];
			NSNumber* oid = [res valueForKey: @"oid"];
			[role setOid: [oid PGTSOidValue]];
			[role setName: [res valueForKey: @"rolname"]];
			
			[roles addObject: role];
		}
		
		[mDatabase setRoles: roles];
	}
	
	query = 
	@"SELECT roleid, member "
	@" FROM pg_auth_members ";
	res = [connection executeQuery: query];
	
	{
		NSMutableDictionary *membersByRoleOid = [NSMutableDictionary dictionary];
		
		while ([res advanceRow])
		{
			Oid roleOid = [[res valueForKey: @"roleid"] PGTSOidValue];
			Oid memberOid = [[res valueForKey: @"member"] PGTSOidValue];
			PGTSRoleDescription* member = [mDatabase roleWithOid: memberOid];
			
			NSMutableArray *members = FindObject (membersByRoleOid, roleOid);
			if (! members)
			{
				members = [NSMutableArray array];
				Insert (membersByRoleOid, roleOid, members);
			}
			[members addObject: member];
		}
		
		for (NSNumber *key in [membersByRoleOid keyEnumerator])
		{
			PGTSRoleDescription* role = [mDatabase roleWithOid: [key PGTSOidValue]];
			[role setMembers: [membersByRoleOid objectForKey: key]];
		}
	}
}


- (void) fetchRelations: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	ExpectV (connection);
	NSString* query = 
	@"SELECT c.oid, c.relnamespace, c.relname, c.relkind, c.relacl, c.relowner "
	@" FROM pg_class c "
	@" INNER JOIN pg_namespace n ON c.relnamespace = n.oid "
	@" WHERE c.relkind IN ('r', 'v') AND "
	@"  n.nspname NOT IN ('information_schema', 'baseten') AND "
	@"  n.nspname NOT LIKE 'pg_%'";
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded]);
	
	{
		while ([res advanceRow]) 
		{
			Oid oid = [[res valueForKey: @"oid"] PGTSOidValue];
			PGTSTableDescription* table = [loadState tableWithOid: oid descriptionClass: [self tableDescriptionClass]];
			[table setName: [res valueForKey: @"relname"]];
			unichar kind = [[res valueForKey: @"relkind"] characterAtIndex: 0];
			ExpectV (kind <= UCHAR_MAX);
			[table setKind: kind];
			[table setACL: [res valueForKey: @"relacl"]];
			
			[table setOwner: [mDatabase roleWithOid: [[res valueForKey: @"relowner"] PGTSOidValue]]];
			[table setSchema: [loadState schemaWithOid: [[res valueForKey: @"relnamespace"] PGTSOidValue]]];
		}
	}
}


- (void) fetchInheritance: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	ExpectV (connection);
	NSString* query =
	@"SELECT inhrelid, inhparent FROM pg_inherits ORDER BY inhrelid, inhseqno";
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded]);
	
	{
		NSMutableDictionary *inheritedOidsByTableOid = [NSMutableDictionary dictionary];
		
		while ([res advanceRow])
		{
			NSNumber *inhrelid = [res valueForKey: @"inhrelid"];
			NSNumber *inhparent = [res valueForKey: @"inhparent"];
			NSMutableArray *oids = [inheritedOidsByTableOid objectForKey: inhrelid];
			if (! oids)
			{
				oids = [NSMutableArray array];
				[oids addObject: inhparent];
			}
		}
		
		for (NSNumber *key in inheritedOidsByTableOid)
		{
			Oid reloid = [key PGTSOidValue];
			PGTSTableDescription* table = [loadState tableWithOid: reloid];
			ExpectV (table);
			[table setInheritedOids: [inheritedOidsByTableOid objectForKey: key]];
		}
	}
}


- (void) fetchColumns: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	ExpectV (connection);
	
	{
		NSString* query = 
		@"SELECT a.attrelid, a.attname, a.attnum, a.atttypid, a.attnotnull, a.attinhcount, pg_get_expr (d.adbin, d.adrelid, false) AS default "
		@" FROM pg_attribute a "
		@" INNER JOIN pg_class c ON a.attrelid = c.oid "
		@" INNER JOIN pg_namespace n ON n.oid = c.relnamespace "
		@" LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid and a.attnum = d.adnum "
		@" WHERE a.attisdropped = false AND "
		@"  c.relkind IN ('r', 'v') AND "
		@"  n.nspname NOT IN ('information_schema', 'baseten') AND "
		@"  n.nspname NOT LIKE 'pg_%'";
		
		PGTSResultSet* res = [connection executeQuery: query];
		ExpectV ([res querySucceeded]);
		
		NSMutableDictionary *columnsByTable = [NSMutableDictionary dictionary];
		
		while ([res advanceRow])
		{
			Oid typeOid = [[res valueForKey: @"atttypid"] PGTSOidValue];
			Oid relid = [[res valueForKey: @"attrelid"] PGTSOidValue];
			NSInteger inhcount = [[res valueForKey: @"attinhcount"] integerValue];
			PGTSTypeDescription* typeDesc = [mDatabase typeWithOid: typeOid];
			PGTSColumnDescription* column = nil;
			if ([@"xml" isEqualToString: [typeDesc name]])
				column = [[[PGTSXMLColumnDescription alloc] init] autorelease];
			else
				column = [[[PGTSColumnDescription alloc] init] autorelease];
			
			[column setType: typeDesc];
			[column setName: [res valueForKey: @"attname"]];
			[column setIndex: [[res valueForKey: @"attnum"] integerValue]];
			[column setNotNull: [[res valueForKey: @"attnotnull"] boolValue]];
			[column setInherited: (0 == inhcount ? NO : YES)];
			[column setDefaultValue: [res valueForKey: @"default"]];
			//FIXME: mark inherited columns.
			
			NSMutableArray *columns = FindObject (columnsByTable, relid);
			if (! columns)
			{
				columns = [NSMutableArray array];
				Insert (columnsByTable, relid, columns);
			}
			[columns addObject: column];
		}
		
		for (NSNumber *key in [columnsByTable keyEnumerator])
		{
			Oid relid = [key PGTSOidValue];
			NSArray *columns = [columnsByTable objectForKey: key];
			PGTSTableDescription *table = [loadState tableWithOid: relid];
			ExpectV (table);
			[table setColumns: columns];
		}
	}
	
	{
		//Fetch some column-specific constraints.
		//We can't determine whether a column accepts only XML document from its type.
		//Instead, we have to look for a constraint like 'CHECK ((column) IS DOCUMENT)'
		//or 'CHECK ("Column" IS DOCUMENT)'. We do this by comparing the constraint 
		//definition to an expression, where a number of parentheses is allowed around 
		//its parts. We use the reconstructed constraint instead of what the user wrote.
		NSString* query =
		@"SELECT conrelid, conkey "
		@"FROM ( "
		@"  SELECT c.conrelid, c.conkey [1], a.attname, "
		@"    regexp_matches (pg_get_constraintdef (c.oid, false), "
		@"	    '^CHECK ?[(]+(?:\"([^\"]+)\")|([^( ][^ )]*)[ )]+IS DOCUMENT[ )]+$' "
		@"    ) AS matches "
		@"  FROM pg_constraint c "
		@"  INNER JOIN pg_attribute a ON (c.conrelid = a.attrelid AND c.conkey [1] = a.attnum) "
		@"  INNER JOIN pg_type t ON (t.oid = a.atttypid AND t.typname = 'xml') "
		@"	WHERE c.contype = 'c' AND 1 = array_upper (c.conkey, 1) "
		@") c "
		@"WHERE attname = ANY (matches)";
		PGTSResultSet* res = [connection executeQuery: query];
		ExpectV ([res querySucceeded])
		
		while ([res advanceRow])
		{
			Oid relid = [[res valueForKey: @"conrelid"] PGTSOidValue];
			NSInteger attnum = [[res valueForKey: @"conkey"] integerValue];
			PGTSTableDescription *table = [loadState tableWithOid: relid];
			ExpectV (table);
			[[table columnAtIndex: attnum] setRequiresDocuments: YES];
		}
	}
}


- (void) fetchUniqueIndexes: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	ExpectV (connection);
	//indexrelid is oid of the index, indrelid of the table.
	NSString* query = 
	@"SELECT i.indexrelid, i.indrelid, c.relname, i.indisprimary, i.indkey::INTEGER[] "
	@" FROM pg_index i "
	@" INNER JOIN pg_class c ON i.indexrelid = c.oid "
	@" INNER JOIN pg_namespace n ON c.relnamespace = n.oid "
	@" WHERE i.indisunique = true AND "
	@"  n.nspname NOT IN ('information_schema', 'baseten') AND "
	@"  n.nspname NOT LIKE 'pg_%' "
	@" ORDER BY i.indrelid ASC, i.indisprimary DESC";
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded]);

	{
		while ([res advanceRow]) 
		{
			NSNumber *relidObject = [res valueForKey: @"indrelid"];
			Oid relid = [relidObject PGTSOidValue];
			Oid oid = [[res valueForKey: @"indexrelid"] PGTSOidValue];
			
			PGTSIndexDescription *index = [loadState addIndexForRelation: relid];
			PGTSTableDescription *table = [loadState tableWithOid: relid];
			ExpectV (table);

			[index setName: [res valueForKey: @"relname"]];
			[index setOid: oid];
			[index setPrimaryKey: [[res valueForKey: @"indisprimary"] boolValue]];
			
			NSArray* indkey = [res valueForKey: @"indkey"];
			NSMutableSet* columns = [NSMutableSet setWithCapacity: [indkey count]];
			BXEnumerate (currentIndex, e, [indkey objectEnumerator])
			{
				NSInteger i = [currentIndex integerValue];
				if (0 < i)
				{
					id column = [table columnAtIndex: i];
					ExpectV (column);
					[columns addObject: column];
				}
			}
			[index setColumns: columns];
		}
	}
}


- (id) databaseDescription
{
	id retval = nil;
	@synchronized (self)
	{
		retval = [[mDatabase retain] autorelease];
	}
	return retval;
}


- (void) loadUsing: (PGTSConnection *) connection
{
	[mDatabase release];
	mDatabase = [[[self databaseDescriptionClass] alloc] init];
	
	PGTSMetadataContainerLoadState *loadState = [[[self loadStateClass] alloc] init];
	
	[self loadUsing: connection loadState: loadState];
	[loadState assignSchemas: mDatabase];
	[loadState assignUniqueIndexes: mDatabase];

	[loadState release];
}


- (void) loadUsing: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	//Order is important.
	[self fetchTypes: connection loadState: loadState];
	[self fetchRoles: connection loadState: loadState];	
	[self fetchSchemas: connection loadState: loadState];	
	[self fetchRelations: connection loadState: loadState];
	[self fetchColumns: connection loadState: loadState];
	[self fetchUniqueIndexes: connection loadState: loadState];
	[self fetchInheritance: connection loadState: loadState];	
}



- (void) prepareForConnection: (PGTSConnection *) connection
{
	@synchronized (self)
	{
		if (! mDatabase)
			[self loadUsing: connection];
	}
}


- (void) reloadUsingConnection: (PGTSConnection *) connection
{
	@synchronized (self)
	{
		[self loadUsing: connection];
	}
}
@end
