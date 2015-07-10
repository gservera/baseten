//
// UndoTests.m
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

@interface UndoTests : BXDatabaseTestCase 
{
}
- (void) undoAutocommit: (BOOL) autocommit;
- (void) undoWithMTORelationshipAutocommit: (BOOL) autocommit;
@end

@implementation UndoTests
- (BXDatabaseObject *) objectWithId: (unsigned int) anId entity: (BXEntityDescription *) entity
{
    NSArray* res = [mContext executeFetchForEntity: entity
                                    withPredicate: [NSPredicate predicateWithFormat: @"id = %u", anId]
                                            error: nil];
    BXDatabaseObject* object = [res objectAtIndex: 0];
    return object;
}

- (void) undoAutocommit: (BOOL) autocommit
{
    if (autocommit)
    {
        [mContext setAutocommits: YES];
        XCTAssertTrue ([mContext autocommits]);
    }
    else
    {
        XCTAssertFalse ([mContext autocommits]);
    }
    
    const unsigned int objectId = 5;
	[mContext connectSync: NULL];
    NSUndoManager* undoManager = [mContext undoManager];
    BXEntityDescription* updatetest = [[mContext databaseObjectModel] entityForTable: @"updatetest"];

    XCTAssertNotNil (undoManager);
    XCTAssertNotNil (updatetest);
    
    BXDatabaseObject* object = [self objectWithId: objectId entity: updatetest];
    NSNumber* oldValue = [object primitiveValueForKey: @"value1"];
    NSNumber* newValue = [NSNumber numberWithInt: [oldValue unsignedIntValue] + 1];
    [object setPrimitiveValue: newValue forKey: @"value1"];
    
    XCTAssertEqualObjects ([object primitiveValueForKey: @"value1"], newValue);
    NSNumber* fetchedValue = [[self objectWithId: objectId entity: updatetest] primitiveValueForKey: @"value1"];
    XCTAssertEqualObjects (fetchedValue, newValue);
    
    [undoManager undo];
	id currentValue = [object primitiveValueForKey: @"value1"];
    XCTAssertEqualObjects (currentValue, oldValue);
    fetchedValue = [[self objectWithId: objectId entity: updatetest] primitiveValueForKey: @"value1"];
    XCTAssertEqualObjects (fetchedValue, oldValue);    
}

- (void) undoWithMTORelationshipAutocommit: (BOOL) autocommit
{    
    if (YES == autocommit)
    {
        [mContext setAutocommits: YES];
        XCTAssertTrue ([mContext autocommits]);
    }
    else
    {
        XCTAssertFalse ([mContext autocommits]);
    }
    
	const unsigned int objectId = 1;
    [mContext connectIfNeeded: nil];
    NSUndoManager* undoManager = [mContext undoManager];
    XCTAssertNotNil (undoManager);	

    BXEntityDescription* test1 = [[mContext databaseObjectModel] entityForTable: @"test1" inSchema: @"Fkeytest"];
	XCTAssertNotNil (test1);

    BXDatabaseObject* object = [self objectWithId: objectId entity: test1];

    XCTAssertNotNil (object);
    
    NSMutableSet* foreignObjects = [object primitiveValueForKey: @"test2Set"];
    BXDatabaseObject* foreignObject = [foreignObjects anyObject];
    [foreignObjects removeObject: foreignObject];
    XCTAssertTrue (1 == [foreignObjects count]);
	//FIXME: this should really be fetched from a different database context since now we get the same object we fetched earlier.
    NSMutableSet* foreignObjects2 = [[self objectWithId: objectId entity: test1] primitiveValueForKey: @"test2Set"];
    XCTAssertEqualObjects (foreignObjects, foreignObjects2);
    
    [undoManager undo];
    XCTAssertTrue (2 == [foreignObjects count]);
    XCTAssertEqualObjects (foreignObjects, foreignObjects2);    
}

- (void) testUndoWithAutocommit
{
    [self undoAutocommit: YES];
}

- (void) testUndo
{
    [self undoAutocommit: NO];
}

- (void) testUndoWithMTORelationship
{
    [self undoWithMTORelationshipAutocommit: NO];
}

- (void) testUndoWithMTORelationshipAndAutocommit
{
    [self undoWithMTORelationshipAutocommit: YES];
}

@end
