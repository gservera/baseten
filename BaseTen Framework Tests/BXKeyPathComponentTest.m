//
//  BXKeyPathComponentTest.m
//  BaseTen
//
//  Created by Guillem on 8/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <BaseTen/BXKeyPathParser.h>

@interface BXKeyPathComponentTest : XCTestCase

@end

@implementation BXKeyPathComponentTest

- (void)testKeyPath {
    NSString* keyPath = @"aa.bb.cc";
    NSArray* components = BXKeyPathComponents (keyPath);
    XCTAssertEqualObjects (components, ([NSArray arrayWithObjects: @"aa", @"bb", @"cc", nil]));
}

- (void)testQuotedKeyPath {
    NSString* keyPath = @"\"aa.bb\".cc";
    NSArray* components = BXKeyPathComponents (keyPath);
    XCTAssertEqualObjects (components, ([NSArray arrayWithObjects: @"aa.bb", @"cc", nil]));
}

- (void)testSingleComponent {
    NSString* keyPath = @"aa";
    NSArray* components = BXKeyPathComponents (keyPath);
    XCTAssertEqualObjects (components, ([NSArray arrayWithObjects: @"aa", nil]));
}

- (void)testRecurringFullStops {
    NSString* keyPath = @"aa..bb";
    XCTAssertThrowsSpecificNamed (BXKeyPathComponents (keyPath), NSException, NSInvalidArgumentException);
}

- (void)testEndingFullStop {
    NSString* keyPath = @"aa.";
    XCTAssertThrowsSpecificNamed (BXKeyPathComponents (keyPath), NSException, NSInvalidArgumentException);
}

- (void)testBeginningFullStop {
    NSString* keyPath = @".aa";
    XCTAssertThrowsSpecificNamed (BXKeyPathComponents (keyPath), NSException, NSInvalidArgumentException);
}

@end
