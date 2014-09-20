//
//  NSPredicate+BaseTenAdditionsTests.m
//  BaseTen
//
//  Created by Guillem on 12/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <BaseTen/NSPredicate+BaseTenAdditions.h>

@interface NSPredicate_BaseTenAdditionsTests : XCTestCase

@end

@implementation NSPredicate_BaseTenAdditionsTests

- (void) test1
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"SELF = $MY_VAR"];
    NSDictionary *vars = [NSDictionary dictionaryWithObject: @"a" forKey: @"MY_VAR"];
    XCTAssertTrue ([predicate BXEvaluateWithObject: @"a" substitutionVariables: vars]);
    XCTAssertFalse ([predicate BXEvaluateWithObject: @"b" substitutionVariables: vars]);
}

@end
