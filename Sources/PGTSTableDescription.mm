//
// PGTSTableDescription.mm
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
