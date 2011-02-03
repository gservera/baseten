//
// BXPGClearLocksHandler.m
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

#import "BXPGClearLocksHandler.h"
#import "BXDatabaseObjectIDPrivate.h"
#import "BXLogger.h"
#import "PGTSAdditions.h"
#import "BXHOM.h"


static void
bx_error_during_clear_notification (id self, NSError* error)
{
	BXLogWarning (@"During clear notification: %@", error);
}


@implementation BXPGClearLocksHandler
+ (NSString *) notificationName
{
	return @"baseten_unlocked_locks";
}

- (void) handleNotification: (PGTSNotification *) notification
{
	PGTSResultSet* xactRes = nil;
	NSError* error = nil;

	xactRes = [mConnection executeQuery: @"BEGIN"];
	if (! [xactRes querySucceeded]) 
	{
		error = [xactRes error];
		goto error;
	}
	
	NSArray* relids = [mInterface observedRelids];
    
    //Which tables have pending locks?
    NSString* query = 
	@"SELECT l.last_date, l.lock_table_name, r.relname, r.nspname "
	@" FROM baseten.pending_locks l "
	@" INNER JOIN baseten.relation r ON (r.id = l.relid) "
	@" WHERE l.last_date > COALESCE ($1, '-infinity')::timestamp "
	@"  AND l.relid = ANY ($2) ";
    PGTSResultSet* res = [mConnection executeQuery: query parameters: mLastCheck, relids];
    if (NO == [res querySucceeded])
	{
		error = [res error];
		goto error;
	}
    
	//Update the timestamp.
	while ([res advanceRow]) 
		[self setLastCheck: [res valueForKey: @"last_date"]];	
	
	//Hopefully not too many tables, because we need to get unlocked rows for each of them.
	//We can't union the queries, either, because the primary key fields differ.
	NSMutableArray* ids = [NSMutableArray array];
	BXDatabaseContext* ctx = [mInterface databaseContext];
	while ([res advanceRow])
	{
		[ids removeAllObjects];
		NSString *query = nil;
		NSString *relname = [res valueForKey: @"relname"];
		NSString *nspname = [res valueForKey: @"nspname"];
		PGTSTableDescription *table = [[mConnection databaseDescription] table: relname inSchema: nspname];
		
		{
			NSString* queryFormat =
			@"SELECT DISTINCT ON (%@) l.* "
			@"FROM %@ l NATURAL INNER JOIN %@ "
			@"WHERE baseten_lock_cleared = true "
			@" AND baseten_lock_backend_pid != pg_backend_pid () "
			@" AND baseten_lock_timestamp > COALESCE ($1, '-infinity')::timestamp ";
						
			//Primary key field names.
			NSArray* pkeyfnames = (id) [[[[table primaryKey] columns] BX_Collect] quotedName: mConnection];
			NSString* pkeystr = [pkeyfnames componentsJoinedByString: @", "];
			
			//Table names.
			NSString* lockTableName = [res valueForKey: @"lock_table_name"];
			NSString* tableName = [table schemaQualifiedName: mConnection];
			
			query = [NSString stringWithFormat: queryFormat, pkeystr, lockTableName, tableName];
		}
		
		{
			PGTSResultSet* unlockedRows = [mConnection executeQuery: query parameters: mLastCheck];
			if (! [unlockedRows querySucceeded])
			{
				error = [unlockedRows error];
				goto error;
			}

			//Get the entity.
			NSString* tableName = [table name];
			NSString* schemaName = [table schemaName];
			BXEntityDescription* entity = [[ctx databaseObjectModel] entityForTable: tableName inSchema: schemaName];
			if (! entity) goto error;
			
			while ([unlockedRows advanceRow])
			{
				NSDictionary* row = [unlockedRows currentRowAsDictionary];
				BXDatabaseObjectID* anID = [BXDatabaseObjectID IDWithEntity: entity primaryKeyFields: row];
				[ids addObject: anID];
			}
		}
		
		//Only one entity allowed per array.
		[[mInterface databaseContext] unlockedObjectsInDatabase: ids];
	}
	xactRes = [mConnection executeQuery: @"COMMIT"];
	if (! [xactRes querySucceeded])
	{
		error = [xactRes error];
		goto error;
	}
    
	return;
	
error:
	[mConnection executeQuery: @"ROLLBACK"];
	bx_error_during_clear_notification (self, error);
}
@end

