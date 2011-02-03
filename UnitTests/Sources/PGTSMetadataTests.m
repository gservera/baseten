//
// PGTSMetadataTests.m
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

#import "PGTSMetadataTests.h"
#import "MKCSenTestCaseAdditions.h"
#import <BaseTen/PGTSConnection.h>
#import <BaseTen/PGTSDatabaseDescription.h>
#import <BaseTen/PGTSSchemaDescription.h>
#import <BaseTen/PGTSTableDescription.h>
#import <BaseTen/PGTSColumnDescription.h>
#import <BaseTen/PGTSIndexDescription.h>
#import <BaseTen/PGTSTypeDescription.h>
#import <BaseTen/BXPGInterface.h>
#import <BaseTen/BXEnumerate.h>


@implementation PGTSMetadataTests
- (void) setUp
{
	[super setUp];
	
	NSDictionary* connectionDictionary = [self connectionDictionary];
	PGTSConnection* connection = [[[PGTSConnection alloc] init] autorelease];
	BOOL status = [connection connectSync: connectionDictionary];
	STAssertTrue (status, [[connection connectionError] description]);
	mDatabaseDescription = [[connection databaseDescription] retain];
	[connection disconnect];
}

- (void) tearDown
{
	[mDatabaseDescription release];
	[super tearDown];
}

- (void) test1Table
{
	MKCAssertNotNil (mDatabaseDescription);
	PGTSTableDescription* table = [mDatabaseDescription table: @"test" inSchema: @"public"];
	MKCAssertNotNil (table);
	MKCAssertEqualObjects (@"test", [table name]);
	MKCAssertEqualObjects (@"public", [[table schema] name]);
}

- (void) test2Columns
{
	MKCAssertNotNil (mDatabaseDescription);
	PGTSTableDescription* table = [mDatabaseDescription table: @"test" inSchema: @"public"];
	MKCAssertNotNil (table);
	NSDictionary* columns = [table columns];
	
	int count = 0;
	BXEnumerate (currentColumn, e, [columns objectEnumerator])
	{
		NSInteger idx = [currentColumn index];
		if (0 < idx)
			count++;
	}
	MKCAssertTrue (2 == count);
	
	{
		PGTSColumnDescription* column = [columns objectForKey: @"id"];
		MKCAssertNotNil (column);
		MKCAssertTrue (1 == [column index]);
		MKCAssertTrue (YES == [column isNotNull]);
		MKCAssertEqualObjects (@"nextval('test_id_seq'::regclass)", [column defaultValue]);
		
		PGTSTypeDescription* type = [column type];
		MKCAssertEqualObjects (@"int4", [type name]);
	}
	
	{
		PGTSColumnDescription* column = [columns objectForKey: @"value"];
		MKCAssertNotNil (column);
		MKCAssertTrue (2 == [column index]);
		MKCAssertTrue (NO == [column isNotNull]);
		MKCAssertNil ([column defaultValue]);
		
		PGTSTypeDescription* type = [column type];
		MKCAssertEqualObjects (@"varchar", [type name]);
	}	
}

- (void) test3Pkey
{
	MKCAssertNotNil (mDatabaseDescription);
	PGTSTableDescription* table = [mDatabaseDescription table: @"test" inSchema: @"public"];
	MKCAssertNotNil (table);
	PGTSIndexDescription* pkey = [table primaryKey];
	
	MKCAssertFalse ([pkey isUnique]);
	MKCAssertTrue ([pkey isPrimaryKey]);
	
	NSSet* columns = [pkey columns];
	MKCAssertTrue (1 == [columns count]);
	
	MKCAssertEqualObjects (@"id", [[columns anyObject] name]);
}
@end
