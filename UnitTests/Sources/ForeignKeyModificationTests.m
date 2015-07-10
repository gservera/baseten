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

#import "ForeignKeyModificationTests.h"
#import "MKCSenTestCaseAdditions.h"


@implementation ForeignKeyModificationTests

- (void) setUp
{
	[super setUp];
    
    mTest1 		= [[[mContext databaseObjectModel] entityForTable: @"test1" inSchema: @"Fkeytest"] retain];
    mTest2 		= [[[mContext databaseObjectModel] entityForTable: @"test2" inSchema: @"Fkeytest"] retain];
    mOtotest1 	= [[[mContext databaseObjectModel] entityForTable: @"ototest1" inSchema: @"Fkeytest"] retain];
    mOtotest2 	= [[[mContext databaseObjectModel] entityForTable: @"ototest2" inSchema: @"Fkeytest"] retain];
    mMtmtest1 	= [[[mContext databaseObjectModel] entityForTable: @"mtmtest1" inSchema: @"Fkeytest"] retain];
    mMtmtest2 	= [[[mContext databaseObjectModel] entityForTable: @"mtmtest2" inSchema: @"Fkeytest"] retain];

    MKCAssertNotNil (mTest1);
    MKCAssertNotNil (mTest2);
    MKCAssertNotNil (mOtotest1);
    MKCAssertNotNil (mOtotest2);
    MKCAssertNotNil (mMtmtest1);
    MKCAssertNotNil (mMtmtest2);

    mTest1v		= [[[mContext databaseObjectModel] entityForTable: @"test1_v" inSchema: @"Fkeytest"] retain];
    mTest2v		= [[[mContext databaseObjectModel] entityForTable: @"test2_v" inSchema: @"Fkeytest"] retain];
    mOtotest1v	= [[[mContext databaseObjectModel] entityForTable: @"ototest1_v" inSchema: @"Fkeytest"] retain];
    mOtotest2v	= [[[mContext databaseObjectModel] entityForTable: @"ototest2_v" inSchema: @"Fkeytest"] retain];
    mMtmtest1v	= [[[mContext databaseObjectModel] entityForTable: @"mtmtest1_v" inSchema: @"Fkeytest"] retain];
    mMtmtest2v	= [[[mContext databaseObjectModel] entityForTable: @"mtmtest2_v" inSchema: @"Fkeytest"] retain];
	mMtmrel1	= [[[mContext databaseObjectModel] entityForTable: @"mtmrel1" inSchema: @"Fkeytest"] retain];
    
    MKCAssertNotNil (mTest1v);
    MKCAssertNotNil (mTest2v);
    MKCAssertNotNil (mOtotest1v);
    MKCAssertNotNil (mOtotest2v);
    MKCAssertNotNil (mMtmtest1v);
    MKCAssertNotNil (mMtmtest2v);
	MKCAssertNotNil (mMtmrel1);
}

- (void) tearDown
{
	[mTest1 release];
	[mTest2 release];	
	[mOtotest1 release];
	[mOtotest2 release];
	[mMtmtest1 release];
	[mMtmtest2 release];
	[mTest1v release];
	[mTest2v release];
	[mOtotest1v release];
	[mOtotest2v release];
	[mMtmtest1v release];
	[mMtmtest2v release];
	[mMtmrel1 release];
	[super tearDown];
}

- (void) modMany: (BXEntityDescription *) manyEntity toOne: (BXEntityDescription *) oneEntity
{
    //Change reference in foreignObject from id=1 to id=2
    NSError* error = nil;
    MKCAssertTrue (NO == [mContext autocommits]);
    
    NSArray* res = [mContext executeFetchForEntity: manyEntity
                                    withPredicate: [NSPredicate predicateWithFormat: @"id = 1"]
                                            error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    MKCAssertTrue (1 == [res count]);
    BXDatabaseObject* foreignObject = [res objectAtIndex: 0];
    MKCAssertTrue ([[foreignObject objectID] entity] == manyEntity);

    res = [mContext executeFetchForEntity: oneEntity
						   withPredicate: [NSPredicate predicateWithFormat: @"id = 2"]
								   error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    MKCAssertTrue (1 == [res count]);
    BXDatabaseObject* object = [res objectAtIndex: 0];
    MKCAssertTrue ([[object objectID] entity] == oneEntity);
    
    MKCAssertFalse ([[foreignObject primitiveValueForKey: [oneEntity name]] isEqual: object]);
    [foreignObject setPrimitiveValue: object forKey: [oneEntity name]];
    MKCAssertEqualObjects ([foreignObject primitiveValueForKey: [oneEntity name]], object);
    
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
    MKCAssertTrue ([[object objectID] entity] == oneEntity);
    
    const int count = 2;
    NSMutableSet* foreignObjects = [NSMutableSet setWithCapacity: count];
    for (int i = 0; i < count; i++)
    {
        BXDatabaseObject* foreignObject = [mContext createObjectForEntity: manyEntity withFieldValues: nil error: &error];
        XCTAssertNotNil (foreignObject, @"%@",[error description]);
        MKCAssertTrue ([[foreignObject objectID] entity] == manyEntity);
        [foreignObjects addObject: foreignObject];
    }
    MKCAssertTrue (count == [foreignObjects count]);
    
	[object setPrimitiveValue: foreignObjects forKey: relationshipName];
    
    NSSet* referencedObjects = [NSSet setWithSet: [object primitiveValueForKey: relationshipName]];
    MKCAssertEqualObjects (referencedObjects, foreignObjects);

    [mContext rollback];
}

- (void) modOne: (BXEntityDescription *) entity1 toOne: (BXEntityDescription *) entity2
{
    //Change a reference in entity1 and entity2
    
    NSError* error = nil;
	XCTAssertTrue ([mContext connectSync: &error], @"%@",[error description]);
	
    MKCAssertFalse ([[[entity1 relationshipsByName] objectForKey: [entity2 name]] isToMany]);
    MKCAssertFalse ([[[entity2 relationshipsByName] objectForKey: [entity1 name]] isToMany]);
    
    NSArray* res = [mContext executeFetchForEntity: entity1
                                    withPredicate: [NSPredicate predicateWithFormat: @"id = 1"]
                                            error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    MKCAssertTrue (1 == [res count]);
    BXDatabaseObject* object = [res objectAtIndex: 0];
    MKCAssertTrue ([[object objectID] entity] == entity1);
    
    res = [mContext executeFetchForEntity: entity2
                           withPredicate: [NSPredicate predicateWithFormat: @"id = 1"]
                                   error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    MKCAssertTrue (1 == [res count]);
    BXDatabaseObject* foreignObject1 = [res objectAtIndex: 0];
    MKCAssertTrue ([[foreignObject1 objectID] entity] == entity2);
    
    BXDatabaseObject* foreignObject2 = [object valueForKey: [entity2 name]];
    MKCAssertFalse ([foreignObject1 isEqual: foreignObject2]);
    MKCAssertFalse (foreignObject1 == foreignObject2);
    MKCAssertTrue ([[foreignObject2 objectID] entity] == entity2);
    
    [object setPrimitiveValue: foreignObject1 forKey: [entity2 name]];
    NSNumber* n1 = [NSNumber numberWithInt: 1];
    MKCAssertEqualObjects (n1, [foreignObject1 primitiveValueForKey: @"r1"]);
    MKCAssertEqualObjects (n1, [object primitiveValueForKey: @"id"]);
    MKCAssertEqualObjects (n1, [foreignObject1 primitiveValueForKey: @"id"]);
    MKCAssertTrue (nil == [foreignObject2 primitiveValueForKey: @"r1"]);
    MKCAssertFalse ([n1 isEqual: [foreignObject2 primitiveValueForKey: @"id"]]);

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
	MKCAssertTrue (0 < [[object primitiveValueForKey: @"test2Set"] count]);
    [object setPrimitiveValue: nil forKey: @"test2Set"];
	MKCAssertTrue (0 == [[object primitiveValueForKey: @"test2Set"] count]);

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
	MKCAssertFalse ([mContext autocommits]);
	
    NSError* error = nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat: @"id = %d", 1];
    MKCAssertNotNil (predicate);
    NSArray* res = [mContext executeFetchForEntity: mTest1
                                    withPredicate: predicate
                                            error: &error];
    XCTAssertNotNil (res, @"%@",[error description]);
    MKCAssertTrue (1 == [res count]);
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
