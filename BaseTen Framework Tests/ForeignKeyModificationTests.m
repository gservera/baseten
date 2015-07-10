//
// ForeignKeyModificationTests.m
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

#import "BXDatabaseTestCase.h"

@interface ForeignKeyModificationTests : BXDatabaseTestCase
{
    BXEntityDescription* mTest1;
    BXEntityDescription* mTest2;
    BXEntityDescription* mOtotest1;
    BXEntityDescription* mOtotest2;
    BXEntityDescription* mMtmtest1;
    BXEntityDescription* mMtmtest2;
    
    BXEntityDescription* mTest1v;
    BXEntityDescription* mTest2v;
    BXEntityDescription* mOtotest1v;
    BXEntityDescription* mOtotest2v;
    BXEntityDescription* mMtmtest1v;
    BXEntityDescription* mMtmtest2v;
    BXEntityDescription* mMtmrel1;
}

- (void) modMany: (BXEntityDescription *) manyEntity toOne: (BXEntityDescription *) oneEntity;
- (void) modOne: (BXEntityDescription *) oneEntity toMany: (BXEntityDescription *) manyEntity;
- (void) modOne: (BXEntityDescription *) entity1 toOne: (BXEntityDescription *) entity2;
- (void) remove1: (BXEntityDescription *) oneEntity;
- (void) remove2: (BXEntityDescription *) oneEntity;
@end

@implementation ForeignKeyModificationTests

- (void) setUp
{
	[super setUp];
    
    mTest1 		= [[mContext databaseObjectModel] entityForTable: @"test1" inSchema: @"Fkeytest"];
    mTest2 		= [[mContext databaseObjectModel] entityForTable: @"test2" inSchema: @"Fkeytest"];
    mOtotest1 	= [[mContext databaseObjectModel] entityForTable: @"ototest1" inSchema: @"Fkeytest"];
    mOtotest2 	= [[mContext databaseObjectModel] entityForTable: @"ototest2" inSchema: @"Fkeytest"];
    mMtmtest1 	= [[mContext databaseObjectModel] entityForTable: @"mtmtest1" inSchema: @"Fkeytest"];
    mMtmtest2 	= [[mContext databaseObjectModel] entityForTable: @"mtmtest2" inSchema: @"Fkeytest"];

    XCTAssertNotNil (mTest1);
    XCTAssertNotNil (mTest2);
    XCTAssertNotNil (mOtotest1);
    XCTAssertNotNil (mOtotest2);
    XCTAssertNotNil (mMtmtest1);
    XCTAssertNotNil (mMtmtest2);

    mTest1v		= [[mContext databaseObjectModel] entityForTable: @"test1_v" inSchema: @"Fkeytest"];
    mTest2v		= [[mContext databaseObjectModel] entityForTable: @"test2_v" inSchema: @"Fkeytest"];
    mOtotest1v	= [[mContext databaseObjectModel] entityForTable: @"ototest1_v" inSchema: @"Fkeytest"];
    mOtotest2v	= [[mContext databaseObjectModel] entityForTable: @"ototest2_v" inSchema: @"Fkeytest"];
    mMtmtest1v	= [[mContext databaseObjectModel] entityForTable: @"mtmtest1_v" inSchema: @"Fkeytest"];
    mMtmtest2v	= [[mContext databaseObjectModel] entityForTable: @"mtmtest2_v" inSchema: @"Fkeytest"];
	mMtmrel1	= [[mContext databaseObjectModel] entityForTable: @"mtmrel1" inSchema: @"Fkeytest"];
    
    XCTAssertNotNil (mTest1v);
    XCTAssertNotNil (mTest2v);
    XCTAssertNotNil (mOtotest1v);
    XCTAssertNotNil (mOtotest2v);
    XCTAssertNotNil (mMtmtest1v);
    XCTAssertNotNil (mMtmtest2v);
	XCTAssertNotNil (mMtmrel1);
}

- (void) modMany: (BXEntityDescription *) manyEntity toOne: (BXEntityDescription *) oneEntity
{
    //Change reference in foreignObject from id=1 to id=2
    NSError* error = nil;
    XCTAssertTrue (NO == [mContext autocommits]);
    
    NSArray* res = [mContext executeFetchForEntity: manyEntity
                                    withPredicate: [NSPredicate predicateWithFormat: @"id = 1"]
                                            error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    XCTAssertTrue (1 == [res count]);
    BXDatabaseObject* foreignObject = [res objectAtIndex: 0];
    XCTAssertTrue ([[foreignObject objectID] entity] == manyEntity);

    res = [mContext executeFetchForEntity: oneEntity
						   withPredicate: [NSPredicate predicateWithFormat: @"id = 2"]
								   error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    XCTAssertTrue (1 == [res count]);
    BXDatabaseObject* object = [res objectAtIndex: 0];
    XCTAssertTrue ([[object objectID] entity] == oneEntity);
    
    XCTAssertFalse ([[foreignObject primitiveValueForKey: [oneEntity name]] isEqual: object]);
    [foreignObject setPrimitiveValue: object forKey: [oneEntity name]];
    XCTAssertEqualObjects ([foreignObject primitiveValueForKey: [oneEntity name]], object);
    
    [mContext rollback];
}

- (void) modOne: (BXEntityDescription *) oneEntity toMany: (BXEntityDescription *) manyEntity
{
    //Create an object to oneEntity and add referencing objects to manyEntity
    NSError* error = nil;
        
    BXDatabaseObject* object = [mContext createObjectForEntity: oneEntity withFieldValues: nil error: &error];
    XCTAssertNotNil (object, @"%@",[error description]);
	//If the set proxy wasn't created earlier, here it will be. This might be useful for debugging.
	NSString *relationshipName = [[manyEntity name] stringByAppendingString: @"Set"];
    XCTAssertTrue (0 == [[object valueForKey: relationshipName] count], @"%@",[[object valueForKey: relationshipName] description]);
    XCTAssertTrue ([[object objectID] entity] == oneEntity);
    
    const int count = 2;
    NSMutableSet* foreignObjects = [NSMutableSet setWithCapacity: count];
    for (int i = 0; i < count; i++)
    {
        BXDatabaseObject* foreignObject = [mContext createObjectForEntity: manyEntity withFieldValues: nil error: &error];
        XCTAssertNotNil (foreignObject, @"%@",[error description]);
        XCTAssertTrue ([[foreignObject objectID] entity] == manyEntity);
        [foreignObjects addObject: foreignObject];
    }
    XCTAssertTrue (count == [foreignObjects count]);
    
	[object setPrimitiveValue: foreignObjects forKey: relationshipName];
    
    NSSet* referencedObjects = [NSSet setWithSet: [object primitiveValueForKey: relationshipName]];
    XCTAssertEqualObjects (referencedObjects, foreignObjects);

    [mContext rollback];
}

- (void) modOne: (BXEntityDescription *) entity1 toOne: (BXEntityDescription *) entity2
{
    //Change a reference in entity1 and entity2
    
    NSError* error = nil;
	XCTAssertTrue ([mContext connectSync: &error], @"%@",[error description]);
	
    XCTAssertFalse ([[[entity1 relationshipsByName] objectForKey: [entity2 name]] isToMany]);
    XCTAssertFalse ([[[entity2 relationshipsByName] objectForKey: [entity1 name]] isToMany]);
    
    NSArray* res = [mContext executeFetchForEntity: entity1
                                    withPredicate: [NSPredicate predicateWithFormat: @"id = 1"]
                                            error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    XCTAssertTrue (1 == [res count]);
    BXDatabaseObject* object = [res objectAtIndex: 0];
    XCTAssertTrue ([[object objectID] entity] == entity1);
    
    res = [mContext executeFetchForEntity: entity2
                           withPredicate: [NSPredicate predicateWithFormat: @"id = 1"]
                                   error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    XCTAssertTrue (1 == [res count]);
    BXDatabaseObject* foreignObject1 = [res objectAtIndex: 0];
    XCTAssertTrue ([[foreignObject1 objectID] entity] == entity2);
    
    BXDatabaseObject* foreignObject2 = [object valueForKey: [entity2 name]];
    XCTAssertFalse ([foreignObject1 isEqual: foreignObject2]);
    XCTAssertFalse (foreignObject1 == foreignObject2);
    XCTAssertTrue ([[foreignObject2 objectID] entity] == entity2);
    
    [object setPrimitiveValue: foreignObject1 forKey: [entity2 name]];
    NSNumber* n1 = [NSNumber numberWithInt: 1];
    XCTAssertEqualObjects (n1, [foreignObject1 primitiveValueForKey: @"r1"]);
    XCTAssertEqualObjects (n1, [object primitiveValueForKey: @"id"]);
    XCTAssertEqualObjects (n1, [foreignObject1 primitiveValueForKey: @"id"]);
    XCTAssertTrue (nil == [foreignObject2 primitiveValueForKey: @"r1"]);
    XCTAssertFalse ([n1 isEqual: [foreignObject2 primitiveValueForKey: @"id"]]);

    [mContext rollback];
}

- (BXDatabaseObject *) removeRefObject: (BXEntityDescription *) entity
{
    NSError* error = nil;
    NSArray* res = [mContext executeFetchForEntity: entity
                                    withPredicate: [NSPredicate predicateWithFormat: @"id = 1"]
                                            error: &error];
    
    XCTAssertNotNil (res, @"%@",[error description]);
    return [res objectAtIndex: 0];
}

- (void) remove1: (BXEntityDescription *) oneEntity
{
    BXDatabaseObject* object = [self removeRefObject: oneEntity];
	XCTAssertTrue (0 < [[object primitiveValueForKey: @"test2Set"] count]);
    [object setPrimitiveValue: nil forKey: @"test2Set"];
	XCTAssertTrue (0 == [[object primitiveValueForKey: @"test2Set"] count]);

    [mContext rollback];
}

- (void) remove2: (BXEntityDescription *) oneEntity
{
    BXDatabaseObject* object = [self removeRefObject: oneEntity];
    NSSet* refObjects = [object primitiveValueForKey: @"test2Set"];
    BXEnumerate (currentObject, e, [[refObjects allObjects] objectEnumerator])
        [currentObject setPrimitiveValue: nil forKey: @"test1"];
    
    [mContext rollback];
}

@end


@implementation ForeignKeyModificationTests (Tests)

- (void) testRemove1
{
    [self remove1: mTest1];
}

- (void) testRemoveView1
{
    [self remove1: mTest1v];
}

- (void) testRemove2
{
    [self remove2: mTest1];
}

- (void) testRemoveView2
{
    [self remove2: mTest1v];
}

- (void) testModMTO
{
    [self modMany: mTest2 toOne: mTest1];
}

- (void) testModMTOView
{
    [self modMany: mTest2v toOne: mTest1v];
}

- (void) testModOTM
{
	//This doesn't work for views (mTest1v, mTest2v) because we don't provide values for the primary key.
    [self modOne: mTest1 toMany: mTest2];
}

- (void) testModOTM2
{
    //FIXME: also write a view test?
	XCTAssertFalse ([mContext autocommits]);
	
    NSError* error = nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat: @"id = %d", 1];
    XCTAssertNotNil (predicate);
    NSArray* res = [mContext executeFetchForEntity: mTest1
                                    withPredicate: predicate
                                            error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    XCTAssertTrue (1 == [res count]);
    BXDatabaseObject* object = [res objectAtIndex: 0];
    //Create a self-updating container to see if it interferes with object creation.
    id collection = [object valueForKey: @"test2Set"];
    
    NSDictionary* values = [NSDictionary dictionaryWithObjectsAndKeys:
							[object primitiveValueForKey: @"id"], @"fkt1id",
							@"test", @"value",
							nil];
    XCTAssertNotNil ([mContext createObjectForEntity: mTest2 withFieldValues: values error: &error], @"%@",[error description]);
    
    collection = nil;
    [mContext rollback];
}

- (void) testModOTO
{
    [self modOne: mOtotest1 toOne: mOtotest2];
}

- (void) testModOTOView
{
    [self modOne: mOtotest1v toOne: mOtotest2v];
}

@end
