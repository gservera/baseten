//
//  BXDatabaseContextTests.m
//  BaseTen
//
//  Created by Guillem on 12/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <BaseTen/BXDatabaseContext.h>

@interface BXDatabaseContextTests : XCTestCase

@end

@implementation BXDatabaseContextTests

- (void) testCreation
{
    id ctx = [[BXDatabaseContext alloc] init];
    XCTAssertNotNil(ctx);
}

@end
