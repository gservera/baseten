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

#import "BXDatabaseTestCase.h"
#import <BaseTen/PGTSConnection.h>
#import <BaseTen/PGTSDatabaseDescription.h>
#import <BaseTen/PGTSSchemaDescription.h>
#import <BaseTen/PGTSTableDescription.h>
#import <BaseTen/PGTSColumnDescription.h>
#import <BaseTen/PGTSIndexDescription.h>
#import <BaseTen/PGTSTypeDescription.h>
#import <BaseTen/BXPGInterface.h>
#import <BaseTen/BXEnumerate.h>

@interface PGTSMetadataTests : BXDatabaseTestCase {
    PGTSDatabaseDescription* mDatabaseDescription;
}
@end

@implementation PGTSMetadataTests

- (void) setUp{
	[super setUp];
	
	NSDictionary* connectionDictionary = [self connectionDictionary];
	PGTSConnection* connection = [[PGTSConnection alloc] init];
	BOOL status = [connection connectSync: connectionDictionary];
	XCTAssertTrue (status == YES, @"%@",[[connection connectionError] description]);
	mDatabaseDescription = [connection databaseDescription];
	[connection disconnect];
}

- (void) test1Table
{
	XCTAssertNotNil (mDatabaseDescription);
	PGTSTableDescription* table = [mDatabaseDescription table: @"test" inSchema: @"public"];
	XCTAssertNotNil (table);
	XCTAssertEqualObjects (@"test", [table name]);
	XCTAssertEqualObjects (@"public", [[table schema] name]);
}

- (void) test2Columns
{
	XCTAssertNotNil (mDatabaseDescription);
	PGTSTableDescription* table = [mDatabaseDescription table: @"test" inSchema: @"public"];
	XCTAssertNotNil (table);
	NSDictionary* columns = [table columns];
	
	int count = 0;
	BXEnumerate (currentColumn, e, [columns objectEnumerator])
	{
		NSInteger idx = [currentColumn index];
		if (0 < idx)
			count++;
	}
	XCTAssertTrue (2 == count);
	
	{
		PGTSColumnDescription* column = [columns objectForKey: @"id"];
		XCTAssertNotNil (column);
		XCTAssertTrue (1 == [column index]);
		XCTAssertTrue (YES == [column isNotNull]);
		XCTAssertEqualObjects (@"nextval('test_id_seq'::regclass)", [column defaultValue]);
		
		PGTSTypeDescription* type = [column type];
		XCTAssertEqualObjects (@"int4", [type name]);
	}
	
	{
		PGTSColumnDescription* column = [columns objectForKey: @"value"];
		XCTAssertNotNil (column);
		XCTAssertTrue (2 == [column index]);
		XCTAssertTrue (NO == [column isNotNull]);
		XCTAssertNil ([column defaultValue]);
		
		PGTSTypeDescription* type = [column type];
		XCTAssertEqualObjects (@"varchar", [type name]);
	}	
}

- (void) test3Pkey
{
	XCTAssertNotNil (mDatabaseDescription);
	PGTSTableDescription* table = [mDatabaseDescription table: @"test" inSchema: @"public"];
	XCTAssertNotNil (table);
	PGTSIndexDescription* pkey = [table primaryKey];
	
	XCTAssertFalse ([pkey isUnique]);
	XCTAssertTrue ([pkey isPrimaryKey]);
	
	NSSet* columns = [pkey columns];
	XCTAssertTrue (1 == [columns count]);
	
	XCTAssertEqualObjects (@"id", [[columns anyObject] name]);
}
@end
