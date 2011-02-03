//
// BXConnectTests.m
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

#import "BXConnectionTests.h"
#import "MKCSenTestCaseAdditions.h"
#import <BaseTen/BaseTen.h>


@implementation BXConnectionTests
- (void) setUp
{
	[super setUp];

    mContext = [[BXDatabaseContext alloc] init];
	[mContext setAutocommits: NO];
	[mContext setDelegate: self];
}


- (void) tearDown
{
	[mContext disconnect];
    [mContext release];
	[super tearDown];
}


- (void) waitForConnectionAttempts: (NSInteger) count
{
	for (NSInteger i = 0; i < 300; i++)
	{
		NSLog (@"Attempt %d, count %d, expected %d", i, mExpectedCount, count);
		if (count == mExpectedCount)
			break;
		
		[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 2.0]];
	}
}


- (void) test1Connect
{
    MKCAssertNoThrow ([mContext setDatabaseURI: [self databaseURI]]);
    MKCAssertNoThrow ([mContext connectIfNeeded: nil]);
}


- (void) test2Connect
{
	NSURL* uri = [self databaseURI];
	NSString* uriString = [uri absoluteString];
	uriString = [uriString stringByAppendingString: @"/"];
	uri = [NSURL URLWithString: uriString];
	
    MKCAssertNoThrow ([mContext setDatabaseURI: uri]);
    MKCAssertNoThrow ([mContext connectIfNeeded: nil]);
}


- (void) test3ConnectFail
{
    MKCAssertNoThrow ([mContext setDatabaseURI: [NSURL URLWithString: @"pgsql://localhost/anonexistantdatabase"]]);
    MKCAssertThrows ([mContext connectIfNeeded: nil]);
}


- (void) test4ConnectFail
{
    MKCAssertNoThrow ([mContext setDatabaseURI: 
        [NSURL URLWithString: @"pgsql://user@localhost/basetentest/a/malformed/database/uri"]]);
    MKCAssertThrows ([mContext connectIfNeeded: nil]);
}


- (void) test5ConnectFail
{
    MKCAssertThrows ([mContext setDatabaseURI: [NSURL URLWithString: @"invalid://user@localhost/invalid"]]);
}


- (void) test7NilURI
{
	NSError* error = nil;
	id fetched = nil;
	BXEntityDescription* entity = [[mContext databaseObjectModel] entityForTable: @"test"];
	fetched = [mContext executeFetchForEntity: entity withPredicate: nil error: &error];
	MKCAssertNotNil (error);
	fetched = [mContext createObjectForEntity: entity withFieldValues: nil error: &error];
	MKCAssertNotNil (error);
}


- (void) expected: (NSNotification *) n
{
	mExpectedCount++;
}


- (void) unexpected: (NSNotification *) n
{
	STAssertTrue (NO, @"Expected connection not to have been made.");
}


- (void) test6ConnectFail
{
	[mContext setDatabaseURI: [NSURL URLWithString: @"pgsql://localhost/anonexistantdatabase"]];
	[[mContext notificationCenter] addObserver: self selector: @selector (expected:) name: kBXConnectionFailedNotification object: nil];
	[[mContext notificationCenter] addObserver: self selector: @selector (unexpected:) name: kBXConnectionSuccessfulNotification object: nil];
	[mContext connectAsync];
	[self waitForConnectionAttempts: 1];
	[mContext connectAsync];
	[self waitForConnectionAttempts: 2];
	[mContext connectAsync];
	[self waitForConnectionAttempts: 3];
	STAssertTrue (3 == mExpectedCount, @"Expected 3 connection attempts while there were %d.", mExpectedCount);
}
@end
