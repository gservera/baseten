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

#import "ObjectIDTests.h"
#import "MKCSenTestCaseAdditions.h"
#import <BaseTen/BaseTen.h>


@implementation ObjectIDTests
- (void) testObjectIDWithURI
{
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"test" inSchema: @"public"];
	MKCAssertNotNil (entity);
	
	NSError *error = nil;
	BXDatabaseObject* object = [[mContext executeFetchForEntity: entity 
											 withPredicate: [NSPredicate predicateWithFormat: @"id == 1"]
													 error: &error] objectAtIndex: 0];
	STAssertNotNil (object, [error description]);
	
	BXDatabaseObjectID* objectID = [object objectID];
	NSURL* uri = [objectID URIRepresentation];
	MKCAssertNotNil (uri);
	
	//Change the URI back to a object id
	BXDatabaseContext* ctx2 = [[[BXDatabaseContext alloc] init] autorelease];
	[ctx2 setDatabaseObjectModelStorage: mStorage];
	[ctx2 setDatabaseURI: [mContext databaseURI]];
	[ctx2 setDelegate: self];
	BXDatabaseObjectID* objectID2 = [[[BXDatabaseObjectID alloc] initWithURI: uri context: ctx2] autorelease];
	MKCAssertNotNil (objectID2);
	MKCAssertEqualObjects (objectID, objectID2);
	
	BXDatabaseObject* fault = [[ctx2 faultsWithIDs: [NSArray arrayWithObject: objectID2]] objectAtIndex: 0];
	MKCAssertNotNil (fault);
	MKCAssertFalse ([ctx2 isConnected]);
}

- (void) testInvalidObjectID
{
	NSURL* uri = [NSURL URLWithString: @"/public/test?id,n=12345" relativeToURL: [mContext databaseURI]];
	BXDatabaseObjectID* anId = [[[BXDatabaseObjectID alloc] initWithURI: uri context: mContext] autorelease];
	MKCAssertNotNil (anId);
	
	NSError* error = nil;
	STAssertTrue ([mContext connectIfNeeded: &error], [error description]);
	
	BXDatabaseObject* object = [mContext objectWithID: anId error: &error];
	MKCAssertNil (object);
	MKCAssertNotNil (error);
	MKCAssertTrue ([[error domain] isEqualToString: kBXErrorDomain]);
	MKCAssertTrue ([error code] == kBXErrorObjectNotFound);
}

- (void) testValidObjectID
{
	NSURL* uri = [NSURL URLWithString: @"/public/test?id,n=1" relativeToURL: [mContext databaseURI]];
	BXDatabaseObjectID* anId = [[[BXDatabaseObjectID alloc] initWithURI: uri context: mContext] autorelease];
	MKCAssertNotNil (anId);
	
	NSError* error = nil;
	STAssertTrue ([mContext connectIfNeeded: &error], [error description]);
	
	BXDatabaseObject* object = [mContext objectWithID: anId error: &error];
	STAssertNotNil (object, [error description]);
}

- (void) testObjectIDFromAnotherContext
{
	BXDatabaseContext *ctx2 = [[[BXDatabaseContext alloc] init] autorelease];
	[ctx2 setDatabaseObjectModelStorage: mStorage];
	[ctx2 setDatabaseURI: [mContext databaseURI]];
	[ctx2 setDelegate: self];
	MKCAssertNotNil (ctx2);
	
	BXEntityDescription* entity = [[ctx2 databaseObjectModel] entityForTable: @"test" inSchema: @"public"];
	MKCAssertNotNil (entity);
	
	NSError *error = nil;
	id objectArray = [ctx2 executeFetchForEntity: entity 
						  		   withPredicate: [NSPredicate predicateWithFormat: @"id == 1"]
								 		   error: &error];
	STAssertNotNil (objectArray, [error description]);
	
	BXDatabaseObjectID* anId = (id) [[objectArray objectAtIndex: 0] objectID];
	MKCAssertNotNil (anId);
	
	STAssertTrue ([mContext connectIfNeeded: &error], [error description]);
	
	BXDatabaseObject* anObject = [mContext objectWithID: anId error: &error];
	STAssertNotNil (anObject, [error description]);
	
	[ctx2 disconnect];
}

@end
