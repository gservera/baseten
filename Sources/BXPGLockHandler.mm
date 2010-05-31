//
// BXPGLockHandler.mm
// BaseTen
//
// Copyright (C) 2006-2008 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://basetenframework.org/licensing/ or by contacting
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

#import "BXPGLockHandler.h"
#import "BXDatabaseObjectIDPrivate.h"
#import "BXLogger.h"
#import "PGTSAdditions.h"



@interface BXPGLockHandlerList : NSObject
{
	NSMutableArray *mForUpdate;
	NSMutableArray *mForDelete;
}
- (void) addForUpdate: (BXDatabaseObjectID *) objectID;
- (void) addForDelete: (BXDatabaseObjectID *) objectID;
@end



@implementation BXPGLockHandlerList
- (void) dealloc
{
	[mForUpdate release];
	[mForDelete release];
	[super dealloc];
}


- (void) addForUpdate: (BXDatabaseObjectID *) objectID
{
	if (! mForUpdate)
		mForUpdate = [[NSMutableArray alloc] init];
	
	[mForUpdate addObject: objectID];
}


- (void) addForDelete: (BXDatabaseObjectID *) objectID
{
	if (! mForDelete)
		mForDelete = [[NSMutableArray alloc] init];

	[mForDelete addObject: objectID];
}


- (NSArray *) forUpdate
{
	return [[mForUpdate copy] autorelease];
}


- (NSArray *) forDelete
{
	return [[mForDelete copy] autorelease];
}
@end



@implementation BXPGLockHandler
- (void) dealloc
{
	[mLockFunctionName release];
	[mLockTableName release];
	[super dealloc];
}

- (void) setLockTableName: (NSString *) aName
{
	if (mLockTableName != aName)
	{
		[mLockTableName release];
		mLockTableName = [aName retain];
	}
}

- (NSString *) lockFunctionName
{
	return mLockFunctionName;
}

- (void) setLockFunctionName: (NSString *) name
{
	if (mLockFunctionName != name)
	{
		[mLockFunctionName release];
		mLockFunctionName = [name retain];
	}
}

- (void) handleNotification: (PGTSNotification *) notification
{
	int backendPID = [mConnection backendPID];
	if ([notification backendPID] != backendPID)
	{
		NSString* query = 
		@"SELECT * FROM %@ "
		@"WHERE baseten_lock_cleared = false "
		@" AND baseten_lock_timestamp > COALESCE ($1, '-infinity')::timestamp "
		@" AND baseten_lock_backend_pid != $2 "
		@"ORDER BY baseten_lock_timestamp ASC";
		query = [NSString stringWithFormat: query, mLockTableName];
		PGTSResultSet* res = [mConnection executeQuery: query parameters: mLastCheck, [NSNumber numberWithInt: backendPID]];
		
		//Update the timestamp.
		while ([res advanceRow]) 
			[self setLastCheck: [res valueForKey: @"baseten_lock_timestamp"]];
		
		//Sort the locks by relation.
		NSMutableDictionary *locksByRelation = [NSMutableDictionary dictionary];
		while ([res advanceRow])
		{
			NSDictionary* row = [res currentRowAsDictionary];
			unichar lockType = [[row valueForKey: @"baseten_lock_query_type"] characterAtIndex: 0];
			NSNumber *relid = [row valueForKey: @"baseten_lock_relid"];
			
			BXPGLockHandlerList *list = [locksByRelation objectForKey: relid];
			if (! list)
			{
				list = [[BXPGLockHandlerList alloc] init];
				[locksByRelation setObject: list forKey: relid];
				[list release];
			}
						
			BXDatabaseObjectID* objectID = [BXDatabaseObjectID IDWithEntity: mEntity primaryKeyFields: row];
			switch (lockType) 
			{
				case 'U':
					[list addForUpdate: objectID];
					break;
					
				case 'D':
					[list addForDelete: objectID];
					break;
			}
		}
		
		//Send changes.
		BXDatabaseContext* ctx = [mInterface databaseContext];
		for (BXPGLockHandlerList *list in locksByRelation)
		{
			NSArray *forUpdate = [list forUpdate];
			NSArray *forDelete = [list forDelete];
			
			if ([forUpdate count])
				[ctx lockedObjectsInDatabase: forUpdate status: kBXObjectLockedStatus];
			
			if ([forDelete count])
				[ctx lockedObjectsInDatabase: forDelete status: kBXObjectDeletedStatus];
		}
	}
}
@end
