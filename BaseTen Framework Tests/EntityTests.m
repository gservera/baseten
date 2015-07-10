//
// EntityTests.m
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

#import "BXDatabaseTestCase.h"
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXEnumerate.h>

@interface EntityTests : BXDatabaseTestCase
{
}
@end

@implementation EntityTests
- (void) test1ValidName
{
	NSString* schemaName = @"Fkeytest";
	NSString* entityName = @"mtocollectiontest1";
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: entityName inSchema: schemaName];
	XCTAssertNotNil (entity);
	XCTAssertEqualObjects ([entity name], entityName);
	XCTAssertEqualObjects ([entity schemaName], schemaName);
}

- (void) test2InvalidName
{
	NSError* error = nil;
	NSString* schemaName = @"public";
	NSString* entityName = @"aNonExistentTable";
	XCTAssertTrue ([mContext connectIfNeeded: &error],@"%@", [error description]);
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: entityName inSchema: schemaName];
	XCTAssertNil (entity);
}

- (void) test3Validation
{
	NSError* error = nil;
	XCTAssertTrue ([mContext connectIfNeeded: &error],@"%@", [error description]);
	//This entity has fields only some of which are primary key.
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"mtmtest2" inSchema: @"Fkeytest"];
	XCTAssertNotNil (entity);
	
	//The entity should be validated
	XCTAssertNotNil ([entity fields]);
	XCTAssertNotNil ([entity primaryKeyFields]);	
}

- (void) test4Sharing
{
	NSString* entityName = @"mtocollectiontest1";
	NSString* schemaName = @"Fkeytest";
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: entityName inSchema: schemaName];
	XCTAssertNotNil (entity);
	
	BXDatabaseContext* ctx2 = [[BXDatabaseContext alloc] init];
	[ctx2 setDatabaseObjectModelStorage: mStorage];
	[ctx2 setDatabaseURI: [mContext databaseURI]];
	[ctx2 setDelegate: self];
	BXEntityDescription* entity2 = [[ctx2 databaseObjectModel] entityForTable: entityName inSchema: schemaName];
	XCTAssertNotNil (entity2);
	XCTAssertTrue (entity == entity2);
}

- (void) test5Exclusion
{
	[mContext connectSync: NULL];
	
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"test"];
	XCTAssertNotNil (entity);
	
	BXAttributeDescription* attr = [[entity attributesByName] objectForKey: @"xmin"];
	XCTAssertNotNil (attr);
	XCTAssertTrue ([attr isExcluded]);
	attr = [[entity attributesByName] objectForKey: @"id"];
	XCTAssertNotNil (attr);
	XCTAssertFalse ([attr isExcluded]);
	attr = [[entity attributesByName] objectForKey: @"value"];
	XCTAssertNotNil (attr);
	XCTAssertFalse ([attr isExcluded]);
}

- (void) test6Hash
{
    BXEntityDescription* e1 = [[mContext databaseObjectModel] entityForTable: @"test2" inSchema: @"Fkeytest"];
    BXEntityDescription* e2 = [[mContext databaseObjectModel] entityForTable: @"test2" inSchema: @"Fkeytest"];
	XCTAssertNotNil (e1);
	XCTAssertNotNil (e2);

    NSSet* container3 = [NSSet setWithObject: e1];
    XCTAssertNotNil ([container3 member: e1]);
    XCTAssertNotNil ([container3 member: e2]);
    XCTAssertTrue ([container3 containsObject: e1]);
    XCTAssertTrue ([container3 containsObject: e2]);
    XCTAssertEqual ([e1 hash], [e2 hash]);
    XCTAssertEqualObjects (e1, e2);
    
    NSArray* container = [NSArray arrayWithObjects: 
        [[mContext databaseObjectModel] entityForTable: @"mtmrel1"  inSchema: @"Fkeytest"],
        [[mContext databaseObjectModel] entityForTable: @"mtmtest1" inSchema: @"Fkeytest"],
        [[mContext databaseObjectModel] entityForTable: @"mtmtest2" inSchema: @"Fkeytest"],
        [[mContext databaseObjectModel] entityForTable: @"ototest1" inSchema: @"Fkeytest"],
        [[mContext databaseObjectModel] entityForTable: @"ototest2" inSchema: @"Fkeytest"],
        [[mContext databaseObjectModel] entityForTable: @"test1"    inSchema: @"Fkeytest"],
        nil];
    NSSet* container2 = [NSSet setWithArray: container];

    BXEnumerate (currentEntity, e, [container objectEnumerator])
    {
        XCTAssertFalse ([e1 hash] == [currentEntity hash]);
        XCTAssertFalse ([e2 hash] == [currentEntity hash]);
        XCTAssertFalse ([e1 isEqualTo: currentEntity]);
        XCTAssertFalse ([e2 isEqualTo: currentEntity]);
        XCTAssertTrue ([container containsObject: currentEntity]);
        XCTAssertTrue ([container2 containsObject: currentEntity]);
        XCTAssertNotNil ([container2 member: currentEntity]);
    }

    XCTAssertFalse ([container containsObject: e1]);
    XCTAssertFalse ([container containsObject: e2]);
    XCTAssertFalse ([container2 containsObject: e1]);
    XCTAssertFalse ([container2 containsObject: e2]);    
}

- (void) test7ViewPkey
{
	NSError *error = nil;
	XCTAssertTrue ([mContext connectIfNeeded: &error],@"%@", [error description]);
	
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"test_v"];
	XCTAssertNotNil (entity);
	
	NSArray* pkeyFields = [entity primaryKeyFields];
	XCTAssertTrue (1 == [pkeyFields count]);
	XCTAssertEqualObjects (@"id", [[pkeyFields lastObject] name]);
}
@end
