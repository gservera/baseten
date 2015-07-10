//
//  PGTSValueTests.m
//  BaseTen
//
//  Created by Guillem on 8/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <BaseTen/PGTSFoundationObjects.h>
#import <BaseTen/PGTSDates.h>

int dx_eq (double a, double b)
{
    double aa = fabs (a);
    double bb = fabs (b);
    return (fabs (aa - bb) <= (FLT_EPSILON * MAX (aa, bb)));
}

@interface PGTSValueTests : XCTestCase

@end

@implementation PGTSValueTests

- (void) testDate
{
    const char* dateString = "2009-05-02";
    NSDate* date = [PGTSDate copyForPGTSResultSet: nil withCharacters: dateString type: nil];
    XCTAssertNotNil (date);
    
    NSUInteger units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    [calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
    NSDateComponents* components = [calendar components: units fromDate: date];
    
    XCTAssertTrue (2009 == [components year]);
    XCTAssertTrue (5 == [components month]);
    XCTAssertTrue (2 == [components day]);
}

- (void) testDateBeforeJulian
{
    const char* dateString = "0100-05-02";
    NSDate* date = [PGTSDate copyForPGTSResultSet: nil withCharacters: dateString type: nil];
    XCTAssertNotNil (date);
    
    NSUInteger units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    [calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
    NSDateComponents* components = [calendar components: units fromDate: date];
    
    XCTAssertTrue(100 == [components year]);
    XCTAssertTrue(5 == [components month]);
    XCTAssertTrue(2 == [components day]);
}

- (void) testDateBeforeCE
{
    const char* dateString = "2009-05-02 BC";
    NSDate* date = [PGTSDate copyForPGTSResultSet: nil withCharacters: dateString type: nil];
    XCTAssertNotNil (date);
    
    NSUInteger units = NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    [calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
    NSDateComponents* components = [calendar components: units fromDate: date];
    
    XCTAssertTrue (2009 == [components year]);
    XCTAssertTrue (5 == [components month]);
    XCTAssertTrue (2 == [components day]);
}

- (void) testTime
{
    const char* dateString = "10:02:05";
    NSDate* date = [PGTSTime copyForPGTSResultSet: nil withCharacters: dateString type: nil];
    XCTAssertNotNil (date);
    
    NSUInteger units = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    [calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
    NSDateComponents* components = [calendar components: units fromDate: date];
    
    XCTAssertTrue (10 == [components hour]);
    XCTAssertTrue (2 == [components minute]);
    XCTAssertTrue (5 == [components second]);
}

- (void) testTimeWithFraction
{
    const char* dateString = "10:02:05.00067";
    NSDate* date = [PGTSTime copyForPGTSResultSet: nil withCharacters: dateString type: nil];
    XCTAssertNotNil (date);
    
    NSUInteger units = NSCalendarUnitEra | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    [calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
    NSDateComponents* components = [calendar components: units fromDate: date];
    
    XCTAssertTrue (10 == [components hour]);
    XCTAssertTrue (2 == [components minute]);
    XCTAssertTrue (5 == [components second]);
    XCTAssertTrue (1 == [components era]);
    
    NSTimeInterval interval = [date timeIntervalSinceReferenceDate];
    NSTimeInterval expected = 36125.00067;
    XCTAssertTrue (dx_eq (expected, interval), @"Expected %f to equal %f.", expected, interval);
}

- (void) testTimeWithTimeZone
{
    const char* dateString = "10:02:05-02";
    NSDate* date = [PGTSTime copyForPGTSResultSet: nil withCharacters: dateString type: nil];
    XCTAssertNotNil (date);
    
    NSUInteger units = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    [calendar setTimeZone: [NSTimeZone timeZoneWithName: @"UTC"]];
    NSDateComponents* components = [calendar components: units fromDate: date];
    
    XCTAssertTrue(12 == [components hour]);
    XCTAssertTrue(2 == [components minute]);
    XCTAssertTrue(5 == [components second]);
}

- (void) testTimeWithTimeZone2 //With minutes in time zone
{
    const char* dateString = "10:02:05+02:03";
    NSDate* date = [PGTSTime copyForPGTSResultSet: nil withCharacters: dateString type: nil];
    XCTAssertNotNil (date);
    
    NSUInteger units = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    [calendar setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 3600 * 2 + 60 * 3]];
    NSDateComponents* components = [calendar components: units fromDate: date];
    
    XCTAssertTrue (10 == [components hour]);
    XCTAssertTrue (2 == [components minute]);
    XCTAssertTrue (5 == [components second]);
}

- (void) testTimeWithTimeZone3 //With seconds in time zone
{
    const char* dateString = "10:02:05+02:03:05";
    NSDate* date = [PGTSTime copyForPGTSResultSet: nil withCharacters: dateString type: nil];
    XCTAssertNotNil (date);
    
    NSUInteger units = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    [calendar setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 3600 * 2 + 60 * 3 + 5]];
    NSDateComponents* components = [calendar components: units fromDate: date];
    
    XCTAssertTrue (10 == [components hour]);
    XCTAssertTrue (2 == [components minute]);
    XCTAssertTrue (5 == [components second]);
}

@end
