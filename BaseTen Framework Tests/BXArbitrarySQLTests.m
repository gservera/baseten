//
// BXArbitrarySQLTests.m
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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
#import <BaseTen/PGTSConnection.h>
#import <BaseTen/PGTSResultSet.h>
#import <BaseTen/BXArraySize.h>
#import <BaseTen/BXEnumerate.h>
#import <OCMock/OCMock.h>

__strong static NSString *kKVOCtx = @"BXArbitrarySQLTestsKVOObservingContext";

@interface BXArbitrarySQLTests : BXDatabaseTestCase
{
    PGTSConnection *mConnection;
    BXEntityDescription *mEntity;
    BXDatabaseObject *mT1, *mT2, *mT3, *mT4;
    OCMockObject *mMock;
}
@end

@implementation BXArbitrarySQLTests
- (void) setUp
{
	[super setUp];
	
	{
		NSDictionary* connectionDictionary = [self connectionDictionary];
		mConnection = [[PGTSConnection alloc] init];
		XCTAssertTrue ([mConnection connectSync: connectionDictionary], @"%@",[[mConnection connectionError] description]);
		
		PGTSResultSet *res = nil;
		XCTAssertNotNil ((res = [mConnection executeQuery: @"UPDATE test SET value = null"]));
		XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	}
	
	{
		mEntity = [[mContext databaseObjectModel] entityForTable: @"test"];
		XCTAssertNotNil (mEntity);
		
		NSError *error = nil;
		NSArray *res = [mContext executeFetchForEntity: mEntity withPredicate: nil error: &error];
		XCTAssertNotNil (res, @"%@",[error description]);
		
		BXEnumerate (currentObject, e, [res objectEnumerator])
		{
			NSInteger objectID = [[currentObject primitiveValueForKey: @"id"] integerValue];
			switch (objectID)
			{
				case 1:
					mT1 = currentObject;
					break;
					
				case 2:
					mT2 = currentObject;
					break;
					
				case 3:
					mT3 = currentObject;
					break;
					
				case 4:
					mT4 = currentObject;
					
				default:
					break;
			}
		}
	}
	
	XCTAssertNotNil (mT1);
	XCTAssertNotNil (mT2);
	XCTAssertNotNil (mT3);
	XCTAssertNotNil (mT4);
	
	NSObject *dummy = [[NSObject alloc] init];
	mMock = [OCMockObject partialMockForObject: dummy];
	BXDatabaseObject *objects [] = {mT1, mT2, mT3, mT4};
	
	for (unsigned int i = 0, count = BXArraySize (objects); i < count; i++)
	{
		[objects [i] addObserver: (id) mMock
					  forKeyPath: @"value" 
						 options: NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew 
						 context: (__bridge void *)(kKVOCtx)];
		
		if (3 != i)
		{
			// The change parameter should be a HC matcher, but such would only be needed here.
			[[mMock expect] observeValueForKeyPath: @"value" ofObject: objects [i] change: OCMOCK_ANY context: (__bridge void *)(kKVOCtx)];
		}
	}
	
	// mT4 is not expected to change.
	NSException *exc = [NSException exceptionWithName: NSInternalInconsistencyException
											   reason: [NSString stringWithFormat: @"Object %@ changed.", mT4]
											 userInfo: nil];
	[[[mMock stub] andThrow: exc] observeValueForKeyPath: OCMOCK_ANY ofObject: mT4 change: OCMOCK_ANY context: (__bridge void *)(kKVOCtx)];	
}


- (void) tearDown
{
	[[mMock stub] observeValueForKeyPath: OCMOCK_ANY ofObject: OCMOCK_ANY change: OCMOCK_ANY context: (__bridge void *)(kKVOCtx)];
    mMock = nil;
	
	PGTSResultSet *res = nil;
	XCTAssertNotNil ((res = [mConnection executeQuery: @"UPDATE test SET value = null"]));
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	
	[super tearDown];
}


- (void) test1UpdateUsingSQLUPDATE
{	
	PGTSResultSet *res = nil;
	XCTAssertNotNil ((res = [mConnection executeQuery: @"UPDATE test SET value = $1 WHERE id != 4" parameters: @"test"]));
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
	[mMock verify];
}


- (void) test2UpdateUsingSQLFunction
{
	NSString *fdecl = 
	@"CREATE FUNCTION test_update_change () RETURNS VOID AS $$ "
	@" UPDATE test SET value = 'test' WHERE id != 4; "
	@"$$ VOLATILE LANGUAGE SQL";

	NSString *queries [] = {@"BEGIN", fdecl, @"SELECT test_update_change ()", @"DROP FUNCTION test_update_change ()", @"COMMIT"};
	for (unsigned int i = 0, count = BXArraySize (queries); i < count; i++)
	{
		PGTSResultSet *res = nil;
		XCTAssertNotNil ((res = [mConnection executeQuery: queries [i]]));
		XCTAssertTrue ([res querySucceeded], @"Error when executing '%@': %@", queries [i], [[res error] description]);
	}
	
	[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
	[mMock verify];
}
@end
