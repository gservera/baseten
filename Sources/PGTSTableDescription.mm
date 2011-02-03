//
// PGTSTableDescription.mm
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

#import "PGTSTableDescription.h"
#import "PGTSColumnDescription.h"
#import "PGTSIndexDescription.h"
#import "BXCollectionFunctions.h"
#import "BXLogger.h"
#import "NSString+PGTSAdditions.h"
#import "PGTSOids.h"


using namespace BaseTen;


@implementation PGTSTableDescription
- (void) dealloc
{
	[mColumnsByName release];
	[mColumnsByIndex release];
	[mUniqueIndexes release];
	[mInheritedOids release];
	[super dealloc];
}


- (NSString *) schemaQualifiedName: (PGTSConnection *) connection
{
	Expect (mSchema);
	NSString* schemaName = [[mSchema name] escapeForPGTSConnection: connection];
	NSString* name = [mName escapeForPGTSConnection: connection];
    return [NSString stringWithFormat: @"\"%@\".\"%@\"", schemaName, name];
}


- (NSString *) schemaName
{
	Expect (mSchema);
	return [mSchema name];
}


- (PGTSIndexDescription *) primaryKey
{
	id retval = nil;
	for (PGTSIndexDescription *desc in mUniqueIndexes)
	{
		if ([desc isPrimaryKey])
			retval = desc;
	}
	return retval;
}

- (PGTSColumnDescription *) columnAtIndex: (NSInteger) idx
{
	return FindObject (mColumnsByIndex, idx);
}

- (NSDictionary *) columns
{
	return [[mColumnsByName retain] autorelease];
}


- (void) iterateInheritedOids: (void (*)(Oid currentOid, void* context)) callback context: (void *) context
{
	for (id oidValue in mInheritedOids)
	{
		Oid oid = [oidValue PGTSOidValue];
		callback (oid, context);
	}
}


- (void) setColumns: (NSArray *) columns
{
	NSMutableDictionary *columnsByIndex = [NSMutableDictionary dictionary];
	NSMutableDictionary *columnsByName = [NSMutableDictionary dictionary];
	
	for (PGTSColumnDescription *column in columns)
	{
		Insert (columnsByIndex, [column index], column);
		Insert (columnsByName, [column name], column);
	}
	
	[mColumnsByIndex release];
	[mColumnsByName release];
	mColumnsByIndex = [columnsByIndex copy];
	mColumnsByName = [columnsByName copy];
}


- (void) setUniqueIndexes: (NSArray *) indices
{
	if (indices != mUniqueIndexes)
	{
		[mUniqueIndexes release];
		mUniqueIndexes = [indices copy];
	}
}


- (void) setInheritedOids: (NSArray *) oids
{
	if (oids != mInheritedOids)
	{
		[mInheritedOids release];
		mInheritedOids = [oids copy];
	}
}
@end
