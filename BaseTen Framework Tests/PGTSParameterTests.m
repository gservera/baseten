//
// PGTSParameterTests.m
// BaseTen
//
// Copyright 2009-2010 Marko Karppinen & Co. LLC.
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

#import <BaseTen/PGTSConnection.h>
#import <BaseTen/PGTSResultSet.h>
#import <BaseTen/PGTSConstants.h>
#import <BaseTen/PGTSFoundationObjects.h>
#import "BXDatabaseTestCase.h"

@interface PGTSParameterTests : BXDatabaseTestCase{
    PGTSConnection* mConnection;
}
@end

@implementation PGTSParameterTests
- (void) setUp
{
	[super setUp];
	NSDictionary* connectionDictionary = [self connectionDictionary];
	mConnection = [[PGTSConnection alloc] init];
	BOOL status = [mConnection connectSync: connectionDictionary];
	XCTAssertTrue (status, @"%@",[[mConnection connectionError] description]);
}

- (void) tearDown
{
	[mConnection disconnect];
	[super tearDown];
}

- (void) test0String
{
    //Precomposed and astral characters.
    NSString* value = @"teståäöÅÄÖĤħĪķ";
    //Decomposed and astral characters.
    const char* expected = [[value decomposedStringWithCanonicalMapping] UTF8String];
	
	size_t length = 0;
	id objectValue = [value PGTSParameter: mConnection];
	const char* paramValue = [objectValue PGTSParameterLength: &length connection: mConnection];
	
	//CFRetain (objectValue);
	XCTAssertFalse ([value PGTSIsBinaryParameter]);
	XCTAssertTrue (value == objectValue);
	//XCTAssertTrue (0 == strcmp (expected, paramValue));
    XCTAssertEqualObjects([NSString stringWithUTF8String:expected], [NSString stringWithUTF8String:paramValue],@"Fail");
	//CFRelease (objectValue);
}

- (void) test1Data
{
	const char* value = "\000\001\002\003";
	size_t valueLength = strlen (value);
	
	size_t length = 0;
	NSData* object = [NSData dataWithBytes: value length: length];
	id objectValue = [object PGTSParameter: mConnection];
	const char* paramValue = [objectValue PGTSParameterLength: &length connection: mConnection];
	
	//CFRetain (objectValue);
	XCTAssertTrue ([object PGTSIsBinaryParameter]);
	XCTAssertTrue (object == objectValue);
	XCTAssertTrue (length == valueLength);
	XCTAssertTrue (0 == memcmp (value, paramValue, length));
	//CFRelease (objectValue);
}

- (void) test2Integer
{
	NSInteger value = -15;
	
	size_t length = 0;
	NSNumber* object = [NSNumber numberWithInteger: value];
	id objectValue = [object PGTSParameter: mConnection];
	const char* paramValue = [objectValue PGTSParameterLength: &length connection: mConnection];
	
	//CFRetain (objectValue);
	XCTAssertFalse ([object PGTSIsBinaryParameter]);
	XCTAssertFalse (object == objectValue);
	XCTAssertTrue (0 == strcmp ("-15", paramValue));
	//CFRelease (objectValue);
}

- (void) test3Double
{
	double value = -15.2;
	
	size_t length = 0;
	NSNumber* object = [NSNumber numberWithDouble: value];
	id objectValue = [object PGTSParameter: mConnection];
	const char* paramValue = [objectValue PGTSParameterLength: &length connection: mConnection];
	
	//CFRetain (objectValue);
	XCTAssertFalse ([object PGTSIsBinaryParameter]);
	XCTAssertFalse (object == objectValue);
	XCTAssertTrue (0 == strcmp ("-15.2", paramValue));
	//CFRelease (objectValue);
}

- (void) test4Date
{
	//20010105 8:02 am
	NSDate* object = [NSDate dateWithTimeIntervalSinceReferenceDate: 4 * 86400 + 8 * 3600 + 2 * 60];
	
	size_t length = 0;
	id objectValue = [object PGTSParameter: mConnection];
	const char* paramValue = [objectValue PGTSParameterLength: &length connection: mConnection];
	
	//CFRetain (objectValue);
	XCTAssertFalse ([object PGTSIsBinaryParameter]);
	XCTAssertFalse (object == objectValue);
	XCTAssertTrue (0 == strcmp ("2001-01-05 08:02:00+00", paramValue));
	//CFRelease (objectValue);
}

/* DISABLED. NSCALENDARDATE IS DEPRECATED
- (void) test5CalendarDate
{
	//20010105 8:02 am UTC-1
	NSTimeZone* tz = [NSTimeZone timeZoneForSecondsFromGMT: -3600];
	NSDateComponents *comps = [[NSDateComponents alloc] init];
    comps.year = 2001;
    comps.month = 1;
    comps.day = 5;
    comps.hour = 7;
    comps.minute = 2;
    comps.second = 0;
    comps.timeZone = tz;
    NSDate* object = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] dateFromComponents:comps];
	
    NSDateComponents *components = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] componentsInTimeZone:tz fromDate:<#(NSDate *)#>
    
	size_t length = 0;
	id objectValue = [object PGTSParameter: mConnection];
	const char* paramValue = [objectValue PGTSParameterLength: &length connection: mConnection];
	
	//CFRetain (objectValue);
	XCTAssertFalse ([object PGTSIsBinaryParameter]);
	XCTAssertFalse (object == objectValue);
    XCTAssertEqualObjects([NSString stringWithUTF8String:paramValue], @"2001-01-05 09:02:00+00",@"Calendardates not matching %@ - %@",[NSString stringWithUTF8String:paramValue],@"2001-01-05 09:02:00+00");
	//CFRelease (objectValue);
}*/

- (void) test6Array
{
	NSArray* value = [NSArray arrayWithObjects: @"test", @"-1", nil];
	
	size_t length = 0;
	id objectValue = [value PGTSParameter: mConnection];
	const char* paramValue = [objectValue PGTSParameterLength: &length connection: mConnection];
	
	//CFRetain (objectValue);
	XCTAssertFalse ([value PGTSIsBinaryParameter]);
	XCTAssertFalse (value == objectValue);
	XCTAssertTrue (0 == strcmp ("{\"test\",\"-1\"}", paramValue));
	//CFRelease (objectValue);
}

- (void) test7Set
{
	NSSet* value = [NSSet set];
	size_t length = 0;
	XCTAssertThrowsSpecificNamed ([value PGTSParameter: mConnection], NSException, NSInvalidArgumentException);
	XCTAssertThrowsSpecificNamed ([value PGTSParameterLength: &length connection: mConnection], NSException, NSInvalidArgumentException);
}

- (void) test8Null
{
	NSNull* value = [NSNull null];
	
	size_t length = 0;
	id objectValue = [value PGTSParameter: mConnection];
	const char* paramValue = [objectValue PGTSParameterLength: &length connection: mConnection];
	
	//CFRetain (objectValue);
	XCTAssertTrue (NULL == paramValue);
	//CFRelease (objectValue);
}

- (void) testTimestamp
{
	NSTimeInterval interval = 263856941.04633799; //This caused problems.
	NSDate* value = [NSDate dateWithTimeIntervalSinceReferenceDate: interval];
	
	size_t length = 0;
	id objectValue = [value PGTSParameter: mConnection];
	const char* paramValue = [objectValue PGTSParameterLength: &length connection: mConnection];
	
	//CFRetain (objectValue);
	XCTAssertFalse ([value PGTSIsBinaryParameter]);
	XCTAssertFalse (value == objectValue);
	XCTAssertTrue (0 == strcmp ("2009-05-12 21:35:41.046338+00", paramValue));
	//CFRelease (objectValue);
}

- (void) testTimestamp2
{
	NSTimeInterval interval = 263856941.0000002; //Fractional part that rounds to six zeros.
	NSDate* value = [NSDate dateWithTimeIntervalSinceReferenceDate: interval];
	
	size_t length = 0;
	id objectValue = [value PGTSParameter: mConnection];
	const char* paramValue = [objectValue PGTSParameterLength: &length connection: mConnection];
	
	//CFRetain (objectValue);
	XCTAssertFalse ([value PGTSIsBinaryParameter]);
	XCTAssertFalse (value == objectValue);
	XCTAssertTrue (0 == strcmp ("2009-05-12 21:35:41.000000+00", paramValue));
	//CFRelease (objectValue);
}					
@end
