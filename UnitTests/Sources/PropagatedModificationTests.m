//
// PropagatedModificationTests.m
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

#import "PropagatedModificationTests.h"
#import "MKCSenTestCaseAdditions.h"

#import <BaseTen/BaseTen.h>
#import <BaseTen/BXDatabaseObjectIDPrivate.h>
#import <BaseTen/BXEntityDescriptionPrivate.h>


/* We currently don't support view modifications using partial keys. */

@implementation PropagatedModificationTests

- (void) setUp
{
    context = [[BXDatabaseContext alloc] initWithDatabaseURI: [self databaseURI]];
	[context setAutocommits: NO];
	NSError* error = nil;
    entity = [[context databaseObjectModel] entityForTable: @"test"];
    MKCAssertNotNil (entity);
}

- (void) tearDown
{
	[context disconnect];
    [context release];
}

- (void) testView
{
    NSString* value = @"value";
    NSString* oldValue = nil;
    [context setAutocommits: YES];

    BXEntityDescription* viewEntity = [[context databaseObjectModel] entityForTable: @"test_v"];
	MKCAssertNotNil (viewEntity);

    NSPredicate* predicate = [NSPredicate predicateWithFormat: @"id = 1"];
    MKCAssertNotNil (predicate);
    
    NSError* error = nil;
    NSArray* res = [context executeFetchForEntity: entity withPredicate: predicate error: &error];
    XCTAssertNotNil (res, [error description]);
    MKCAssertTrue (1 == [res count]);
    
    NSArray* res2 = [context executeFetchForEntity: viewEntity withPredicate: predicate error: &error];
    XCTAssertNotNil (res2, [error description]);
    MKCAssertTrue (1 == [res2 count]);
    
    BXDatabaseObject* object = [res objectAtIndex: 0];
    BXDatabaseObject* viewObject = [res2 objectAtIndex: 0];
    MKCAssertFalse ([object isFaultKey: nil]);
    MKCAssertFalse ([viewObject isFaultKey: nil]);
    oldValue = [object valueForKey: @"value"];
    MKCAssertEqualObjects ([object valueForKey: @"id"], [viewObject valueForKey: @"id"]);
    MKCAssertEqualObjects (oldValue, [viewObject valueForKey: @"value"]);
    
    [object setValue: value forKey: @"value"];
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
    MKCAssertTrue ([viewObject isFaultKey: nil]);
    MKCAssertEqualObjects ([viewObject valueForKey: @"value"], value);
    
    //Clean up
    [object setValue: oldValue forKey: @"value"];
    
    [context setAutocommits: NO];
}

@end
