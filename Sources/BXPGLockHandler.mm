//
// BXPGLockHandler.mm
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
		@"SELECT * FROM baseten.%@ "
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
