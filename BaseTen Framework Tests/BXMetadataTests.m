//
// BXMetadataTests.m
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

#import "BXDatabaseTestCase.h"
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXPGInterface.h>
#import <BaseTen/BXPGDatabaseDescription.h>
#import <BaseTen/PGTSConnection.h>
#import <BaseTen/PGTSTableDescription.h>
#import <BaseTen/PGTSIndexDescription.h>


@interface BXMetadataTests : BXDatabaseTestCase
{
    BXPGDatabaseDescription* mDatabaseDescription;
}
@end

@implementation BXMetadataTests
- (void) setUp
{
	[super setUp];
	
	[BXPGInterface class]; // Run +initialize.
	
	NSDictionary* connectionDictionary = [self connectionDictionary];
	PGTSConnection* connection = [[PGTSConnection alloc] init];
	BOOL status = [connection connectSync: connectionDictionary];
	XCTAssertTrue (status, @"%@",[[connection connectionError] description]);
	
	mDatabaseDescription = (id)[connection databaseDescription];
	XCTAssertEqualObjects ([mDatabaseDescription class], [BXPGDatabaseDescription class]);
	
	[connection disconnect];
}


- (void) test1Compatibility
{
	XCTAssertTrue ([mDatabaseDescription hasCompatibleBaseTenSchemaVersion]);
}


- (void) test2SchemaVersion
{
	NSNumber *currentVersion = [BXPGVersion currentVersionNumber];
	NSNumber *currentCompatVersion = [BXPGVersion currentCompatibilityVersionNumber];
	
	XCTAssertEqualObjects (currentCompatVersion, [mDatabaseDescription schemaCompatibilityVersion]);
	XCTAssertEqualObjects (currentVersion, [mDatabaseDescription schemaVersion]);
}


- (void) test3ViewPkey
{
	XCTAssertNotNil (mDatabaseDescription);
	PGTSTableDescription* table = [mDatabaseDescription table: @"test_v" inSchema: @"public"];
	XCTAssertNotNil (table);
	PGTSIndexDescription* pkey = [table primaryKey];
	
	XCTAssertNotNil (pkey);
	XCTAssertFalse ([pkey isUnique]);
	XCTAssertTrue ([pkey isPrimaryKey]);
	
	NSSet* columns = [pkey columns];
	XCTAssertTrue (1 == [columns count]);
	
	XCTAssertEqualObjects (@"id", [[columns anyObject] name]);
}
@end
