//
// PGTSNotificationTests.m
// BaseTen
//
// Copyright 2009 Marko Karppinen & Co. LLC.
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
#import <BaseTen/PGTSConstants.h>
#import <BaseTen/PGTSConnection.h>
#import <BaseTen/PGTSResultSet.h>

@interface PGTSNotificationTests : BXDatabaseTestCase <PGTSConnectionDelegate>{
    PGTSConnection* mConnection;
    BOOL mGotNotification;
}
@end

@implementation PGTSNotificationTests
- (void) PGTSConnectionFailed: (PGTSConnection *) connection
{
}

- (void) PGTSConnectionEstablished: (PGTSConnection *) connection
{
}

- (void) PGTSConnectionLost: (PGTSConnection *) connection error: (NSError *) error
{
}

- (void) PGTSConnection: (PGTSConnection *) connection gotNotification: (PGTSNotification *) notification
{
	mGotNotification = YES;
}

- (void) PGTSConnection: (PGTSConnection *) connection receivedNotice: (NSError *) notice
{
}

- (FILE *) PGTSConnectionTraceFile: (PGTSConnection *) connection
{
	return NULL;
}

- (void) PGTSConnection: (PGTSConnection *) connection networkStatusChanged: (SCNetworkConnectionFlags) newFlags
{
}

- (void) setUp
{
	[super setUp];
	
	NSDictionary* connectionDictionary = [self connectionDictionary];
	mConnection = [[PGTSConnection alloc] init];
	BOOL status = [mConnection connectSync: connectionDictionary];
	XCTAssertTrue (status, @"%@",[[mConnection connectionError] description]);
	
	[mConnection setDelegate: self];
}	

- (void) tearDown
{
	[mConnection disconnect];
	[super tearDown];
}

- (void) testNotification
{
	PGTSResultSet* res = nil;
	res = [mConnection executeQuery: @"LISTEN test_notification"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	res = [mConnection executeQuery: @"NOTIFY test_notification"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);

	XCTAssertTrue (mGotNotification);
}
@end
