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
#import "BXCollections.h"
#import "BXCollectionFunctions.h"
#import "BXScannedMemoryAllocator.h"
#import "BXLogger.h"
#import "NSString+PGTSAdditions.h"


using namespace BaseTen;
using namespace BaseTen::CollectionFunctions;
using namespace PGTS;


@implementation PGTSTableDescription
- (id) init
{
	if ((self = [super init]))
	{
		mColumnsByIndex = new IndexMap ();
		mUniqueIndexes = new IdList ();
		mColumnLock = [[NSLock alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[mColumnLock release];
	[mColumnsByName release];
	
	delete mColumnsByIndex;
	delete mUniqueIndexes;
	
	if (mInheritedOids)
		delete mInheritedOids;
	
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
	Expect (mUniqueIndexes);
	id retval = nil;
	IdList::const_iterator it = mUniqueIndexes->begin ();
	if (mUniqueIndexes->end () != it && [**it isPrimaryKey])
		retval = **it;
	return retval;
}

- (PGTSColumnDescription *) columnAtIndex: (NSInteger) idx
{
	return FindObject (mColumnsByIndex, idx);
}

- (NSDictionary *) columns
{
	id retval = nil;
	[mColumnLock lock];
	if (! mColumnsByName)
		mColumnsByName = [[CreateCFMutableDictionaryWithNames (mColumnsByIndex) autorelease] copy];
	
	retval = [[mColumnsByName retain] autorelease];
	[mColumnLock unlock];
	
	return retval;
}


- (void) iterateInheritedOids: (void (*)(Oid currentOid, void* context)) callback context: (void *) context
{
	if (mInheritedOids)
	{
		for (OidList::const_iterator it = mInheritedOids->begin (), end = mInheritedOids->end ();
			it != end; it++)
		{
			callback (*it, context);
		}
	}
}


- (void) addIndex: (PGTSIndexDescription *) anIndex
{
	ExpectV (anIndex);
	PushBack (mUniqueIndexes, anIndex);
}

- (void) addColumn: (PGTSColumnDescription *) column
{
	ExpectV (column);
	
	[mColumnLock lock];
	if (mColumnsByName)
	{
		[mColumnsByName release];
		mColumnsByName = nil;
	}
	[mColumnLock unlock];
	
	int idx = [column index];
	InsertConditionally (mColumnsByIndex, idx, column);
}

- (void) addInheritedOid: (Oid) anOid
{
	ExpectV (InvalidOid != anOid)
	
	if (! mInheritedOids)
		mInheritedOids = new OidList ();
	mInheritedOids->push_back (anOid);
}
@end
