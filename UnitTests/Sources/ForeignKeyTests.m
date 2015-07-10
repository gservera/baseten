//
// ForeignKeyTests.m
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

#import <BaseTen/BaseTen.h>
#import <BaseTen/BXEnumerate.h>
#import <BaseTen/BXEntityDescriptionPrivate.h>
#import <BaseTen/BXRelationshipDescriptionPrivate.h>

#import "ForeignKeyTests.h"
#import "MKCSenTestCaseAdditions.h"


@implementation ForeignKeyTests

- (void) setUp
{
	[super setUp];

    mTest1 = [[mContext databaseObjectModel] entityForTable: @"test1" inSchema: @"Fkeytest"];
    mTest2 = [[mContext databaseObjectModel] entityForTable: @"test2" inSchema: @"Fkeytest"];
    mOtotest1 = [[mContext databaseObjectModel] entityForTable: @"ototest1" inSchema: @"Fkeytest"];
    mOtotest2 = [[mContext databaseObjectModel] entityForTable: @"ototest2" inSchema: @"Fkeytest"];
    mMtmtest1 = [[mContext databaseObjectModel] entityForTable: @"mtmtest1" inSchema: @"Fkeytest"];
    mMtmtest2 = [[mContext databaseObjectModel] entityForTable: @"mtmtest2" inSchema: @"Fkeytest"];

    MKCAssertNotNil (mTest1);
    MKCAssertNotNil (mTest2);
    MKCAssertNotNil (mOtotest1);
    MKCAssertNotNil (mOtotest2);
    MKCAssertNotNil (mMtmtest1);
    MKCAssertNotNil (mMtmtest2);

    mTest1v = [[mContext databaseObjectModel] entityForTable: @"test1_v" inSchema: @"Fkeytest"];
    mTest2v = [[mContext databaseObjectModel] entityForTable: @"test2_v" inSchema: @"Fkeytest"];
    mOtotest1v = [[mContext databaseObjectModel] entityForTable: @"ototest1_v" inSchema: @"Fkeytest"];
    mOtotest2v = [[mContext databaseObjectModel] entityForTable: @"ototest2_v" inSchema: @"Fkeytest"];
    mMtmtest1v = [[mContext databaseObjectModel] entityForTable: @"mtmtest1_v" inSchema: @"Fkeytest"];
    mMtmtest2v = [[mContext databaseObjectModel] entityForTable: @"mtmtest2_v" inSchema: @"Fkeytest"];
	mMtmrel1 = [[mContext databaseObjectModel] entityForTable: @"mtmrel1" inSchema: @"Fkeytest"];
    
    MKCAssertNotNil (mTest1v);
    MKCAssertNotNil (mTest2v);
    MKCAssertNotNil (mOtotest1v);
    MKCAssertNotNil (mOtotest2v);
    MKCAssertNotNil (mMtmtest1v);
    MKCAssertNotNil (mMtmtest2v);
	MKCAssertNotNil (mMtmrel1);
}

- (void) test1MTO
{
    [self many: mTest2 toOne: mTest1];
}

- (void) test4MTOView
{
    [self many: mTest2v toOne: mTest1v];
}

- (void) many: (BXEntityDescription *) manyEntity toOne: (BXEntityDescription *) oneEntity
{
    NSError* error = nil;
    for (int i = 1; i <= 3; i++)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat: @"id = %d", i];
        MKCAssertNotNil (predicate);
		
        NSArray* res = [mContext executeFetchForEntity: manyEntity
                                        withPredicate: predicate
                                                error: &error];
        XCTAssertNotNil (res, @"%@",[error description]);
        MKCAssertTrue (1 == [res count]);
    
        BXDatabaseObject* object = [res objectAtIndex: 0];
		MKCAssertEquals (1, [object isFaultKey: [oneEntity name]]);
		
        BXDatabaseObject* foreignObject = [object primitiveValueForKey: [oneEntity name]];

        //See that the object has the given entity
        MKCAssertTrue ([[object objectID] entity] == manyEntity);
        
        //The row with id == 3 has null value for the foreign key
        if (3 == i)
        {
            MKCAssertNil (foreignObject);
            MKCAssertNil ([object valueForKeyPath: @"test1.value"]);
        }
        else
        {
            MKCAssertNotNil (foreignObject);
            //See that the object has the given entity
            MKCAssertTrue ([[foreignObject objectID] entity] == oneEntity);
            MKCAssertTrue ([@"11" isEqualToString: [foreignObject valueForKey: @"value"]]);
            MKCAssertTrue ([@"11" isEqualToString: [object valueForKeyPath: @"test1.value"]]);
        }
    }
}

- (void) test1OTM
{
    [self one: mTest1 toMany: mTest2];
}

- (void) test4OTMView
{
    [self one: mTest1v toMany: mTest2v];
}

- (void) one: (BXEntityDescription *) oneEntity toMany: (BXEntityDescription *) manyEntity
{
    NSError* error = nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat: @"id = %d", 1];
    MKCAssertNotNil (predicate);
    NSArray* res = [mContext executeFetchForEntity: oneEntity
                                    withPredicate: predicate
                                            error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    MKCAssertTrue (1 == [res count]);
    BXDatabaseObject* object = [res objectAtIndex: 0];

    //See that the object has the given entity
    MKCAssertTrue ([[object objectID] entity] == oneEntity);
    
    BXRelationshipDescription* rel = [[manyEntity relationshipsByName] objectForKey: [oneEntity name]];
    MKCAssertNotNil (rel);
    MKCAssertFalse ([rel isToMany]);
	rel = [rel inverseRelationship];
    MKCAssertNotNil (rel);
    MKCAssertTrue ([rel isToMany]);
        
    NSSet* foreignObjects = [rel targetForObject: object error: &error];
    XCTAssertNotNil (foreignObjects, @"%@",[error description]);
    MKCAssertTrue (2 == [foreignObjects count]);
    NSArray* values = [foreignObjects valueForKey: @"value"];
    MKCAssertTrue ([values containsObject: @"21"]);
    MKCAssertTrue ([values containsObject: @"22"]);    
    //See that the objects have the given entities
    BXEnumerate (currentObject, e, [foreignObjects objectEnumerator])
        MKCAssertTrue ([[currentObject objectID] entity] == manyEntity);

    foreignObjects = [object valueForKey: [[manyEntity name] stringByAppendingString: @"Set"]];
    MKCAssertTrue (2 == [foreignObjects count]);
    values = [foreignObjects valueForKey: @"value"];
    MKCAssertTrue ([values containsObject: @"21"]);
    MKCAssertTrue ([values containsObject: @"22"]);
    //See that the objects have the given entities
    BXEnumerate (currentObject, e, [foreignObjects objectEnumerator])
        MKCAssertTrue ([[currentObject objectID] entity] == manyEntity);
}

- (void) test2OTO
{
    [self one: mOtotest1 toOne: mOtotest2];
}

- (void) test5OTOView
{
    [self one: mOtotest1v toOne: mOtotest2v];
}

- (void) one: (BXEntityDescription *) entity1 toOne: (BXEntityDescription *) entity2
{
    NSError* error = nil;
	
	XCTAssertTrue ([mContext connectIfNeeded: &error], @"%@",[error description]);
	
    BXRelationshipDescription* foobar = [[entity1 relationshipsByName] objectForKey: [entity2 name]];
    MKCAssertNotNil (foobar);
    MKCAssertFalse ([foobar isToMany]);
	MKCAssertFalse ([[foobar inverseRelationship] isToMany]);

    NSArray* res = [mContext executeFetchForEntity: entity1 
                                    withPredicate: [NSPredicate predicateWithFormat: @"1 <= id && id <= 2"]
                                            error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    MKCAssertTrue (2 == [res count]);
    for (int i = 0; i < 2; i++)
    {
        BXDatabaseObject* object = [res objectAtIndex: i];
        
        BXDatabaseObject* foreignObject  = [object primitiveValueForKey: [entity2 name]];
        BXDatabaseObject* foreignObject2 = [foobar targetForObject: object error: &error];
        XCTAssertNotNil (foreignObject2, @"%@",[error description]);
        
        BXDatabaseObject* object2 = [foreignObject primitiveValueForKey: [entity1 name]];
        BXDatabaseObject* object3 = [[foobar inverseRelationship] targetForObject: foreignObject error: &error];
        XCTAssertNotNil (object3, @"%@",[error description]);
        
        MKCAssertTrue ([[foreignObject  objectID] entity] == entity2);
        MKCAssertTrue ([[foreignObject2 objectID] entity] == entity2);
        MKCAssertTrue ([[object  objectID] entity] == entity1);
        MKCAssertTrue ([[object2 objectID] entity] == entity1);
        MKCAssertTrue ([[object3 objectID] entity] == entity1);
        MKCAssertEqualObjects (foreignObject, foreignObject2);
        MKCAssertEqualObjects (object, object2);
        MKCAssertEqualObjects (object2, object3);

        //See that the objects have the given entities
        MKCAssertTrue ([[object  objectID] entity] == entity1);
        MKCAssertTrue ([[object2 objectID] entity] == entity1);
        MKCAssertTrue ([[object3 objectID] entity] == entity1);
        MKCAssertTrue ([[foreignObject  objectID] entity] == entity2);
        MKCAssertTrue ([[foreignObject2 objectID] entity] == entity2);

        NSNumber* value = [object valueForKey: @"id"];
        NSNumber* value2 = [foreignObject valueForKey: @"id"];
        MKCAssertFalse ([value isEqual: value2]);
    }
    
    res = [mContext executeFetchForEntity: entity2
                           withPredicate: [NSPredicate predicateWithFormat: @"id = 3"]
                                   error: &error];
    XCTAssertNotNil (res,@"%@", [error description]);
    MKCAssertTrue (1 == [res count]);
    BXDatabaseObject* object = [res objectAtIndex: 0];
    MKCAssertNil ([object valueForKey: [entity1 name]]);
    MKCAssertTrue ([[object objectID] entity] == entity2);
}

- (void) test3MTM
{
    [self many: mMtmtest1 toMany: mMtmtest2];
}

- (void) test6MTMView
{
    [self many: mMtmtest1v toMany: mMtmtest2v];
}

- (void) many: (BXEntityDescription *) entity1 toMany: (BXEntityDescription *) entity2
{
    NSError* error = nil;
    NSArray* res = [mContext executeFetchForEntity: entity1 withPredicate: nil error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    MKCAssertTrue (4 == [res count]);
    
    NSSet* expected1 = [NSSet setWithObjects: @"a1", @"b1", @"c1", nil];
    NSSet* expected2 = [NSSet setWithObjects: @"a2", @"b2", @"c2", nil];
    
    BXEnumerate (object, e, [res objectEnumerator])
    {
        MKCAssertTrue ([[object objectID] entity] == entity1);
        
        NSSet* foreignObjects = [object primitiveValueForKey: [[entity2 name] stringByAppendingString: @"Set"]];
        MKCAssertNotNil (foreignObjects);
        if ([@"d1" isEqualToString: [object valueForKey: @"value1"]])
        {
            MKCAssertTrue (1 == [foreignObjects count]);
            BXDatabaseObject* foreignObject = [foreignObjects anyObject];
            MKCAssertTrue ([[foreignObject objectID] entity] == entity2);

            MKCAssertEqualObjects ([foreignObject valueForKey: @"value2"], @"d2");
            NSSet* objects = [foreignObject valueForKey: [[entity1 name] stringByAppendingString: @"Set"]];
            MKCAssertTrue (1 == [objects count]);
            BXDatabaseObject* backRef = [objects anyObject];
            MKCAssertTrue ([[backRef objectID] entity] == entity1);
            MKCAssertEqualObjects ([backRef valueForKey: @"value1"], @"d1");
        }
        else
        {
            MKCAssertTrue (3 == [foreignObjects count]);
            
            NSSet* values2 = [foreignObjects valueForKey: @"value2"];
            MKCAssertEqualObjects (values2, expected2);
            
            BXEnumerate (foreignObject, e, [foreignObjects objectEnumerator])
            {
                MKCAssertTrue ([[foreignObject objectID] entity] == entity2);
                NSArray* objects = [foreignObject valueForKey: [[entity1 name] stringByAppendingString: @"Set"]];
                MKCAssertNotNil (objects);
                MKCAssertTrue (3 == [objects count]);
                
                NSSet* values1 = [objects valueForKey: @"value1"];
                MKCAssertEqualObjects (values1, expected1);
                
                BXEnumerate (backRef, e, [objects objectEnumerator])
                    MKCAssertTrue ([[backRef objectID] entity] == entity1);
            }
        }
    }
}

- (void) test3MTMHelper
{
	[self MTMHelper: mMtmtest1];
}

- (void) test6MTMHelperView
{
	[self MTMHelper: mMtmtest1v];
}

- (void) MTMHelper: (BXEntityDescription *) entity
{
	NSError* error = nil;
	NSArray* res = [mContext executeFetchForEntity: entity
									withPredicate: [NSPredicate predicateWithFormat: @"id = 1"]
											error: &error];
	XCTAssertNotNil (res, @"%@",[error description]);
	BXDatabaseObject* object = [res objectAtIndex: 0];
	NSSet* helperObjects = [object primitiveValueForKey: @"mtmrel1Set"];
	MKCAssertTrue (3 == [helperObjects count]);
	BXEnumerate (currentObject, e, [helperObjects objectEnumerator])
	{
		MKCAssertTrue ([[currentObject objectID] entity] == mMtmrel1);
		MKCAssertTrue (1 == [[currentObject valueForKey: @"id1"] intValue]);
	}
}
    
@end
