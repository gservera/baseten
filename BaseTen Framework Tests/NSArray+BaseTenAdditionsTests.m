//
//  NSArray+BaseTenAdditionsTests.m
//  BaseTen
//
//  Created by Guillem on 8/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <BaseTen/NSArray+BaseTenAdditions.h>

@interface NSArray_BaseTenAdditionsTests : XCTestCase

@end

@implementation NSArray_BaseTenAdditionsTests

- (void) test1
{
    NSArray *a = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"SELF = %@", @"b"];
    
    NSMutableArray *others = [NSMutableArray array];
    NSArray *filtered = [a BXFilteredArrayUsingPredicate: predicate others: others substitutionVariables: nil];
    
    XCTAssertEqualObjects (filtered, [NSArray arrayWithObject: @"b"]);
    XCTAssertEqualObjects (others, ([NSArray arrayWithObjects: @"a", @"c", nil]));
}


- (void) test2
{
    NSArray *a = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"SELF = $MY_VAR"];
    
    NSMutableArray *others = [NSMutableArray array];
    NSDictionary *vars = [NSDictionary dictionaryWithObject: @"b" forKey: @"MY_VAR"];
    NSArray *filtered = [a BXFilteredArrayUsingPredicate: predicate others: others substitutionVariables: vars];
    
    XCTAssertEqualObjects (filtered, [NSArray arrayWithObject: @"b"]);
    XCTAssertEqualObjects (others, ([NSArray arrayWithObjects: @"a", @"c", nil]));
}

@end
