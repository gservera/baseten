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

#import "BXMetadataTests.h"
#import "MKCSenTestCaseAdditions.h"
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXPGInterface.h>
#import <BaseTen/BXPGDatabaseDescription.h>
#import <BaseTen/PGTSConnection.h>
#import <BaseTen/PGTSTableDescription.h>
#import <BaseTen/PGTSIndexDescription.h>



@implementation BXMetadataTests
- (void) setUp
{
	[super setUp];
	
	[BXPGInterface class]; // Run +initialize.
	
	NSDictionary* connectionDictionary = [self connectionDictionary];
	PGTSConnection* connection = [[[PGTSConnection alloc] init] autorelease];
	BOOL status = [connection connectSync: connectionDictionary];
	STAssertTrue (status, [[connection connectionError] description]);
	
	mDatabaseDescription = (id) [[connection databaseDescription] retain];
	MKCAssertEqualObjects ([mDatabaseDescription class], [BXPGDatabaseDescription class]);
	
	[connection disconnect];
}


- (void) tearDown
{
	[mDatabaseDescription release];
	[super tearDown];
}


- (void) test1Compatibility
{
	MKCAssertTrue ([mDatabaseDescription hasCompatibleBaseTenSchemaVersion]);
}


- (void) test2SchemaVersion
{
	NSNumber *currentVersion = [BXPGVersion currentVersionNumber];
	NSNumber *currentCompatVersion = [BXPGVersion currentCompatibilityVersionNumber];
	
	MKCAssertEqualObjects (currentCompatVersion, [mDatabaseDescription schemaCompatibilityVersion]);
	MKCAssertEqualObjects (currentVersion, [mDatabaseDescription schemaVersion]);
}


- (void) test3ViewPkey
{
	MKCAssertNotNil (mDatabaseDescription);
	PGTSTableDescription* table = [mDatabaseDescription table: @"test_v" inSchema: @"public"];
	MKCAssertNotNil (table);
	PGTSIndexDescription* pkey = [table primaryKey];
	
	MKCAssertNotNil (pkey);
	MKCAssertFalse ([pkey isUnique]);
	MKCAssertTrue ([pkey isPrimaryKey]);
	
	NSSet* columns = [pkey columns];
	MKCAssertTrue (1 == [columns count]);
	
	MKCAssertEqualObjects (@"id", [[columns anyObject] name]);	
}
@end
