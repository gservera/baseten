//
// CreateTests.m
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
#import <Foundation/Foundation.h>

@interface TestObject : BXDatabaseObject
{
}
@end


@implementation TestObject
@end

@interface CreateTests : BXDatabaseTestCase
{
}
@end

@implementation CreateTests
- (void) testCreate
{
    NSError* error = nil;    
    BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"test"];
    XCTAssertNotNil (entity);
    
    BXDatabaseObject* object = [mContext createObjectForEntity: entity withFieldValues: nil error: &error];
    XCTAssertNotNil (object, @"%@",[error description]);
    [mContext rollback];
}

- (void) testCreateWithFieldValues
{
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"test"];
    XCTAssertNotNil (entity);
	
	NSError* error = nil;
	NSDictionary* values = [NSDictionary dictionaryWithObject: @"test" forKey: @"value"];
	BXDatabaseObject* object = [mContext createObjectForEntity: entity withFieldValues: values error: &error];
	XCTAssertNotNil (object, @"%@",[error description]);
	
	XCTAssertFalse ([object isFaultKey: @"value"]);
	XCTAssertTrue ([[object valueForKey: @"value"] isEqual: [values valueForKey: @"value"]]);
	[mContext rollback];
}

- (void) testCreateWithPrecomposedStringValue
{
	NSString* precomposed = @"åäöÅÄÖ";
	NSString* decomposed = @"åäöÅÄÖ";
	
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"test"];
    XCTAssertNotNil (entity);
	
	NSError* error = nil;
	NSDictionary* values = [NSDictionary dictionaryWithObject: precomposed forKey: @"value"];
	BXDatabaseObject* object = [mContext createObjectForEntity: entity withFieldValues: values error: &error];
	XCTAssertNotNil (object, @"%@",[error description]);
	
	XCTAssertFalse ([object isFaultKey: @"value"]);
	XCTAssertTrue ([[object valueForKey: @"value"] isEqual: decomposed]);
	[mContext rollback];
}

- (void) testCreateCustom
{
    NSError* error = nil;
    Class objectClass = [TestObject class];
    
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"test"];
    XCTAssertNotNil (entity);
	
    [entity setDatabaseObjectClass: objectClass];
    XCTAssertEqualObjects (objectClass, [entity databaseObjectClass]);
    
    BXDatabaseObject* object = [mContext createObjectForEntity: entity withFieldValues: nil error: &error];
    XCTAssertNotNil (object, @"%@",[error description]);
	
    XCTAssertTrue ([object isKindOfClass: objectClass]);    
    [mContext rollback];
}

- (void) testCreateWithRelatedObject
{
	[mContext connectSync: NULL];
	XCTAssertTrue ([mContext isConnected]);
	
	BXEntityDescription* test1 = [[mContext databaseObjectModel] entityForTable: @"test1" inSchema: @"Fkeytest"];
	BXEntityDescription* test2 = [[mContext databaseObjectModel] entityForTable: @"test2" inSchema: @"Fkeytest"];
	XCTAssertNotNil (test1);
	XCTAssertNotNil (test2);
	
	NSError* error = nil;
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"id == 2"];
	NSArray* res = [mContext executeFetchForEntity: test1 withPredicate: predicate error: &error];
	XCTAssertNotNil (res, @"%@",[error description]);
	
	BXDatabaseObject* target = [res lastObject];
	XCTAssertNotNil (target);
	
	NSDictionary* values = [NSDictionary dictionaryWithObject: target forKey: @"test1"];
	BXDatabaseObject* newObject = [mContext createObjectForEntity: test2 withFieldValues: values error: &error];
	XCTAssertNotNil (newObject, @"%@",[error description]);
	
	XCTAssertTrue ([newObject primitiveValueForKey: @"test1"] == target);
	XCTAssertTrue ([[target primitiveValueForKey: @"test2Set"] containsObject: newObject]);
	
	[mContext rollback];
}
@end
