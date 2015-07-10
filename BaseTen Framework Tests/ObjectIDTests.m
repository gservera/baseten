//
// ObjectIDTests.m
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

@interface ObjectIDTests : BXDatabaseTestCase {
    BXDatabaseContext *ctx2;
}

@end

@implementation ObjectIDTests
- (void) testObjectIDWithURI
{
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"test" inSchema: @"public"];
	XCTAssertNotNil (entity);
	
	NSError *error = nil;
	BXDatabaseObject* object = [[mContext executeFetchForEntity: entity 
											 withPredicate: [NSPredicate predicateWithFormat: @"id == 1"]
													 error: &error] objectAtIndex: 0];
	XCTAssertNotNil (object,@"%@", [error description]);
	
	BXDatabaseObjectID* objectID = [object objectID];
	NSURL* uri = [objectID URIRepresentation];
	XCTAssertNotNil (uri);
    object = nil;

	//Change the URI back to a object id
	ctx2 = [[BXDatabaseContext alloc] init];
	[ctx2 setDatabaseObjectModelStorage: mStorage];
	[ctx2 setDatabaseURI: [mContext databaseURI]];
	[ctx2 setDelegate: self];
	BXDatabaseObjectID* objectID2 = [[BXDatabaseObjectID alloc] initWithURI: uri context: ctx2];
	XCTAssertNotNil (objectID2);
	XCTAssertEqualObjects (objectID, objectID2);
    NSArray *objects = @[objectID2];
	__strong BXDatabaseObject* fault = [[ctx2 faultsWithIDs: objects] objectAtIndex: 0];
	XCTAssertNotNil (fault);
    fault = nil;
    objects = nil;
	XCTAssertFalse ([ctx2 isConnected]);
}

- (void) testInvalidObjectID
{
	NSURL* uri = [NSURL URLWithString: @"/public/test?id,n=12345" relativeToURL: [mContext databaseURI]];
	BXDatabaseObjectID* anId = [[BXDatabaseObjectID alloc] initWithURI: uri context: mContext];
	XCTAssertNotNil (anId);
	
	NSError* error = nil;
	XCTAssertTrue ([mContext connectIfNeeded: &error], @"%@",[error description]);
	
	BXDatabaseObject* object = [mContext objectWithID: anId error: &error];
	XCTAssertNil (object);
	XCTAssertNotNil (error);
	XCTAssertTrue ([[error domain] isEqualToString: kBXErrorDomain]);
	XCTAssertTrue ([error code] == kBXErrorObjectNotFound);
}

- (void) testValidObjectID
{
	NSURL* uri = [NSURL URLWithString: @"/public/test?id,n=1" relativeToURL: [mContext databaseURI]];
	BXDatabaseObjectID* anId = [[BXDatabaseObjectID alloc] initWithURI: uri context: mContext];
	XCTAssertNotNil (anId);
	
	NSError* error = nil;
	XCTAssertTrue ([mContext connectIfNeeded: &error], @"%@",[error description]);
	
	BXDatabaseObject* object = [mContext objectWithID: anId error: &error];
	XCTAssertNotNil (object, @"%@",[error description]);
}

- (void) testObjectIDFromAnotherContext
{
	ctx2 = [[BXDatabaseContext alloc] init];
	[ctx2 setDatabaseObjectModelStorage: mStorage];
	[ctx2 setDatabaseURI: [mContext databaseURI]];
	[ctx2 setDelegate: self];
	XCTAssertNotNil (ctx2);
	
	BXEntityDescription* entity = [[ctx2 databaseObjectModel] entityForTable: @"test" inSchema: @"public"];
	XCTAssertNotNil (entity);
	
	NSError *error = nil;
	id objectArray = [ctx2 executeFetchForEntity: entity 
						  		   withPredicate: [NSPredicate predicateWithFormat: @"id == 1"]
								 		   error: &error];
	XCTAssertNotNil (objectArray, @"%@",[error description]);
	
	BXDatabaseObjectID* anId = (id) [[objectArray objectAtIndex: 0] objectID];
	XCTAssertNotNil (anId);
	
	XCTAssertTrue ([mContext connectIfNeeded: &error], @"%@",[error description]);
	
	BXDatabaseObject* anObject = [mContext objectWithID: anId error: &error];
	XCTAssertNotNil (anObject, @"%@",[error description]);
	
	[ctx2 disconnect];
}

@end
