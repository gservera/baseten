//
// PGTSValueTests.m
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

#import "PGTSValueTests.h"
#import "MKCSenTestCaseAdditions.h"
#import <BaseTen/PGTSFoundationObjects.h>
#import <BaseTen/PGTSDates.h>

@implementation PGTSValueTests
- (void) testDate
{
	const char* dateString = "2009-05-02";
	NSDate* date = [[PGTSDate copyForPGTSResultSet: nil withCharacters: dateString type: nil] autorelease];
	MKCAssertNotNil (date);
	
	NSUInteger units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	[calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
	NSDateComponents* components = [calendar components: units fromDate: date];
	
	MKCAssertTrue (2009 == [components year]);
	MKCAssertTrue (5 == [components month]);
	MKCAssertTrue (2 == [components day]);
}

- (void) testDateBeforeJulian
{
	const char* dateString = "0100-05-02";
	NSDate* date = [[PGTSDate copyForPGTSResultSet: nil withCharacters: dateString type: nil] autorelease];
	MKCAssertNotNil (date);
	
	NSUInteger units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	[calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
	NSDateComponents* components = [calendar components: units fromDate: date];
	
	MKCAssertTrue (100 == [components year]);
	MKCAssertTrue (5 == [components month]);
	MKCAssertTrue (2 == [components day]);
}

- (void) testDateBeforeCE
{
	const char* dateString = "2009-05-02 BC";
	NSDate* date = [[PGTSDate copyForPGTSResultSet: nil withCharacters: dateString type: nil] autorelease];
	MKCAssertNotNil (date);
	
	NSUInteger units = NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	[calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
	NSDateComponents* components = [calendar components: units fromDate: date];
	
	MKCAssertTrue (2009 == [components year]);
	MKCAssertTrue (5 == [components month]);
	MKCAssertTrue (2 == [components day]);
}

- (void) testTime
{
	const char* dateString = "10:02:05";
	NSDate* date = [[PGTSTime copyForPGTSResultSet: nil withCharacters: dateString type: nil] autorelease];
	MKCAssertNotNil (date);
	
	NSUInteger units = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	[calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
	NSDateComponents* components = [calendar components: units fromDate: date];
	
	MKCAssertTrue (10 == [components hour]);
	MKCAssertTrue (2 == [components minute]);
	MKCAssertTrue (5 == [components second]);
}

- (void) testTimeWithFraction
{
	const char* dateString = "10:02:05.00067";
	NSDate* date = [[PGTSTime copyForPGTSResultSet: nil withCharacters: dateString type: nil] autorelease];
	MKCAssertNotNil (date);
	
	NSUInteger units = NSEraCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	[calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
	NSDateComponents* components = [calendar components: units fromDate: date];
	
	MKCAssertTrue (10 == [components hour]);
	MKCAssertTrue (2 == [components minute]);
	MKCAssertTrue (5 == [components second]);
	MKCAssertTrue (1 == [components era]);
	
	NSTimeInterval interval = [date timeIntervalSinceReferenceDate];
	NSTimeInterval expected = 36125.00067;
	STAssertTrue (d_eq (expected, interval), @"Expected %f to equal %f.", expected, interval);
}

- (void) testTimeWithTimeZone
{
	const char* dateString = "10:02:05-02";
	NSDate* date = [[PGTSTime copyForPGTSResultSet: nil withCharacters: dateString type: nil] autorelease];
	MKCAssertNotNil (date);
	
	NSUInteger units = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	[calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
	NSDateComponents* components = [calendar components: units fromDate: date];
	
	MKCAssertTrue (12 == [components hour]);
	MKCAssertTrue (2 == [components minute]);
	MKCAssertTrue (5 == [components second]);
}

- (void) testTimeWithTimeZone2 //With minutes in time zone
{
	const char* dateString = "10:02:05+02:03";
	NSDate* date = [[PGTSTime copyForPGTSResultSet: nil withCharacters: dateString type: nil] autorelease];
	MKCAssertNotNil (date);
	
	NSUInteger units = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	[calendar setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 3600 * 2 + 60 * 3]];
	NSDateComponents* components = [calendar components: units fromDate: date];
	
	MKCAssertTrue (10 == [components hour]);
	MKCAssertTrue (2 == [components minute]);
	MKCAssertTrue (5 == [components second]);
}

- (void) testTimeWithTimeZone3 //With seconds in time zone
{
	const char* dateString = "10:02:05+02:03:05";
	NSDate* date = [[PGTSTime copyForPGTSResultSet: nil withCharacters: dateString type: nil] autorelease];
	MKCAssertNotNil (date);
	
	NSUInteger units = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSCalendar* calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	[calendar setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 3600 * 2 + 60 * 3 + 5]];
	NSDateComponents* components = [calendar components: units fromDate: date];
	
	MKCAssertTrue (10 == [components hour]);
	MKCAssertTrue (2 == [components minute]);
	MKCAssertTrue (5 == [components second]);
}
@end
