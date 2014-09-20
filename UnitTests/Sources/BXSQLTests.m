//
// BXSQLTests.m
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

#import "BXSQLTests.h"
#import "MKCSenTestCaseAdditions.h"
#import <BaseTen/BXDatabaseContextPrivate.h>
#import <BaseTen/BXPGInterface.h>
#import <BaseTen/BXPGTransactionHandler.h>
#import <BaseTen/PGTSConnection.h>
#import <BaseTen/PGTSResultSet.h>


@implementation BXSQLTests
- (NSURL *) databaseURI
{
	return [NSURL URLWithString: @"pgsql://baseten_test_owner@localhost/basetentest"];
}

- (BOOL) checkEnablingForTest: (PGTSConnection *) connection
{
	BOOL retval = NO;
	NSString* query = @"SELECT baseten.is_enabled (id) FROM baseten.relation WHERE nspname = 'public' AND relname = 'test'";
	PGTSResultSet* res = [connection executeQuery: query];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	[res advanceRow];
	retval = [[res valueForKey: @"is_enabled"] boolValue];
	return retval;
}

- (void) testDisableEnable
{
	NSError* error = nil;
	XCTAssertTrue ([mContext connectSync: &error], @"%@",[error description]);
	
	BXPGTransactionHandler* handler = [(BXPGInterface *) [mContext databaseInterface] transactionHandler];
	PGTSConnection* connection = [handler connection];
	MKCAssertNotNil (handler);
	MKCAssertNotNil (connection);
	
	PGTSResultSet* res = nil;
	NSString* query = nil;
	
	res = [connection executeQuery: @"BEGIN"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	MKCAssertTrue ([self checkEnablingForTest: connection]);
	
	query = 
	@"SELECT baseten.disable (c.oid) "
	@" FROM pg_class c "
	@" INNER JOIN pg_namespace n ON (n.oid = c.relnamespace) "
	@" WHERE n.nspname = 'public' AND c.relname = 'test'";
	res = [connection executeQuery: query];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	MKCAssertFalse ([self checkEnablingForTest: connection]);
	
	query = 
	@"SELECT baseten.enable (c.oid) "
	@" FROM pg_class c "
	@" INNER JOIN pg_namespace n ON (n.oid = c.relnamespace) "
	@" WHERE n.nspname = 'public' AND c.relname = 'test'";
	res = [connection executeQuery: query];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);

	MKCAssertTrue ([self checkEnablingForTest: connection]);
	
	res = [connection executeQuery: @"ROLLBACK"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
}

- (void) testPrune
{
	NSError* error = nil;
	XCTAssertTrue ([mContext connectSync: &error], @"%@",[error description]);
	
	BXPGTransactionHandler* handler = [(BXPGInterface *) [mContext databaseInterface] transactionHandler];
	PGTSConnection* connection = [handler connection];
	MKCAssertNotNil (handler);
	MKCAssertNotNil (connection);
	
	NSString* query = nil;
	PGTSResultSet* res = nil;

	query = @"SELECT baseten.prune ()";
	res = [connection executeQuery: query];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	query = @"SELECT COUNT (baseten_modification_id) FROM baseten.modification";
	res = [connection executeQuery: query];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	[res advanceRow];
	MKCAssertTrue (0 == [[res valueForKey: @"count"] integerValue]);
	
	query = @"SELECT COUNT (baseten_lock_id) FROM baseten.lock";
	res = [connection executeQuery: query];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	[res advanceRow];
	MKCAssertTrue (0 == [[res valueForKey: @"count"] integerValue]);	
}
@end
