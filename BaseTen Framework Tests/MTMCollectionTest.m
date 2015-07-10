//
// MTMCollectionTest.m
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

@interface MTMCollectionTest : BXDatabaseTestCase 
{
    BXEntityDescription* mMtmtest1;
    BXEntityDescription* mMtmtest2;    
    BXEntityDescription* mMtmtest1v;
    BXEntityDescription* mMtmtest2v;    
}

- (void) modMany: (BXEntityDescription *) entity1 toMany: (BXEntityDescription *) entity2;

@end

@implementation MTMCollectionTest

- (void) setUp
{
	[super setUp];
    
    mMtmtest1 = [[mContext databaseObjectModel] entityForTable: @"mtmtest1" inSchema: @"Fkeytest"];
    mMtmtest2 = [[mContext databaseObjectModel] entityForTable: @"mtmtest2" inSchema: @"Fkeytest"];
    XCTAssertNotNil (mMtmtest1);
    XCTAssertNotNil (mMtmtest2);
    
    mMtmtest1v = [[mContext databaseObjectModel] entityForTable: @"mtmtest1_v" inSchema: @"Fkeytest"];
    mMtmtest2v = [[mContext databaseObjectModel] entityForTable: @"mtmtest2_v" inSchema: @"Fkeytest"];
    XCTAssertNotNil (mMtmtest1v);
    XCTAssertNotNil (mMtmtest2v);
}

- (void) testModMTM
{
    [self modMany: mMtmtest1 toMany: mMtmtest2];
}

- (void) testModMTMView
{
    [self modMany: mMtmtest1v toMany: mMtmtest2v];
}

- (void) modMany: (BXEntityDescription *) entity1 toMany: (BXEntityDescription *) entity2
{
    //Once again, try to modify an object and see if another object receives the modification.
    //This time, use a many-to-many relationship.

    NSError* error = nil;
    XCTAssertTrue (NO == [mContext autocommits]);
	
    //Execute a fetch
    NSArray* res = [mContext executeFetchForEntity: entity1
									 withPredicate: nil 
											 error: &error];
	XCTAssertNotNil (res, @"%@",[error description]);
    XCTAssertTrue (4 == [res count]);
    
    //Get an object from the result
	NSString *relationshipName = [[entity2 name] stringByAppendingString: @"Set"];
    NSPredicate* predicate = [NSPredicate predicateWithFormat: @"value1 = 'a1'"];
    res =  [res filteredArrayUsingPredicate: predicate];
    XCTAssertTrue (1 == [res count]);
    BXDatabaseObject* object = [res objectAtIndex: 0];
    NSCountedSet* foreignObjects = [object valueForKey: relationshipName];
    NSCountedSet* foreignObjects2 = [object resolveNoncachedRelationshipNamed: relationshipName];
	
    XCTAssertNotNil (foreignObjects);
    XCTAssertNotNil (foreignObjects2);
    XCTAssertTrue (foreignObjects != foreignObjects2);
    XCTAssertTrue ([foreignObjects isEqualToSet: foreignObjects2]);
    
    //Remove the referenced objects (another means than in the previous method)
    [foreignObjects removeAllObjects];
    XCTAssertTrue (0 == [foreignObjects count]);
    XCTAssertTrue ([foreignObjects isEqualToSet: foreignObjects2]);
    
    //Get the objects from the second table
	NSArray *res2 = [mContext executeFetchForEntity: entity2
									  withPredicate: [NSPredicate predicateWithFormat:  @"value2 != 'd2'"]
											  error: &error];
    XCTAssertNotNil (res2, @"%@",[error description]);
    NSSet *objects2 = [NSSet setWithArray: res2];
    XCTAssertTrue (3 == [objects2 count]);
    
    NSMutableSet* mock = [NSMutableSet set];
    BXEnumerate (currentObject, e, [objects2 objectEnumerator])
    {
        [mock addObject: currentObject];
        [foreignObjects addObject: currentObject];
        XCTAssertTrue ([mock isEqualToSet: foreignObjects]);
        XCTAssertTrue ([mock isEqualToSet: foreignObjects2]);
    }
    BXDatabaseObject* anObject = [objects2 anyObject];
    [mock removeObject: anObject];
    [foreignObjects removeObject: anObject];
    XCTAssertTrue ([mock isEqualToSet: foreignObjects]);
    XCTAssertTrue ([mock isEqualToSet: foreignObjects2]);
    
    [mContext rollback];
}

@end
