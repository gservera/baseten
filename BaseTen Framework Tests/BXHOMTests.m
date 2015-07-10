//
//  BXHOMTests.m
//  BaseTen
//
//  Created by Guillem on 8/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <BaseTen/BXHOM.h>

@interface BXHOMTests : XCTestCase

@end

@implementation BXHOMTests

- (void) test01ArrayAny
{
    NSArray *array = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    id object = [array BX_Any];
    XCTAssertTrue ([array containsObject: object]);
}


- (void) test02SetAny
{
    NSSet *set = [NSSet setWithObjects: @"a", @"b", @"c", nil];
    id object = [set BX_Any];
    XCTAssertTrue ([set containsObject: object]);
}


- (void) test03DictAny
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"a", @"1",
                          @"b", @"2",
                          @"c", @"3",
                          nil];
    id object = [dict BX_Any];
    XCTAssertTrue ([[dict allValues] containsObject: object]);
}


- (void) test04SetDo
{
    OCMockObject *m1 = [OCMockObject mockForClass: [NSNumber class]];
    OCMockObject *m2 = [OCMockObject mockForClass: [NSNumber class]];
    [[m1 expect] stringValue];
    [[m2 expect] stringValue];
    
    NSSet *set = [NSSet setWithObjects: m1, m2, nil];
    [[set BX_Do] stringValue];
    
    [m1 verify];
    [m2 verify];
}


- (void) test05ArrayDo
{
    OCMockObject *m1 = [OCMockObject mockForClass: [NSNumber class]];
    OCMockObject *m2 = [OCMockObject mockForClass: [NSNumber class]];
    [[m1 expect] stringValue];
    [[m2 expect] stringValue];
    
    NSArray *array = [NSArray arrayWithObjects: m1, m2, nil];
    [[array BX_Do] stringValue];
    
    [m1 verify];
    [m2 verify];
}


- (void) test06DictDo
{
    OCMockObject *m1 = [OCMockObject mockForClass: [NSNumber class]];
    OCMockObject *m2 = [OCMockObject mockForClass: [NSNumber class]];
    [[m1 expect] stringValue];
    [[m2 expect] stringValue];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          m1, @"a",
                          m2, @"b",
                          nil];
    [[dict BX_Do] stringValue];
    
    [m1 verify];
    [m2 verify];
}


- (void) test07ArrayCollect
{
    NSArray *array1 = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    NSArray *array2 = (id) [[array1 BX_Collect] uppercaseString];
    XCTAssertEqualObjects (array2, ([NSArray arrayWithObjects: @"A", @"B", @"C", nil]));
}


- (void) test08SetCollect
{
    NSSet *set1 = [NSSet setWithObjects: @"a", @"b", @"c", nil];
    NSSet *set2 = (id) [[set1 BX_Collect] uppercaseString];
    XCTAssertEqualObjects (set2, ([NSSet setWithObjects: @"A", @"B", @"C", nil]));
}


- (void) test09DictCollect
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"a", @"1",
                          @"b", @"2",
                          @"c", @"3",
                          nil];
    NSArray *array = (id) [[dict BX_Collect] uppercaseString];
    XCTAssertEqualObjects (array, ([NSArray arrayWithObjects: @"A", @"B", @"C", nil]));
}


- (void) test10ArrayCollectRet
{
    NSArray *array = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    NSSet *set = (id) [[array BX_CollectReturning: [NSMutableSet class]] uppercaseString];
    XCTAssertEqualObjects (set, ([NSSet setWithObjects: @"A", @"B", @"C", nil]));
}


- (void) test11SetCollectRet
{
    NSSet *set = [NSSet setWithObjects: @"a", @"b", @"c", nil];
    NSArray *array = (id) [[set BX_CollectReturning: [NSMutableArray class]] uppercaseString];
    XCTAssertEqualObjects ([array sortedArrayUsingSelector: @selector (compare:)],
                           ([NSArray arrayWithObjects: @"A", @"B", @"C", nil]));
}


- (void) test12DictCollectRet
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"a", @"1",
                          @"b", @"2",
                          @"c", @"3",
                          nil];
    NSSet *set = (id) [[dict BX_CollectReturning: [NSMutableSet class]] uppercaseString];
    XCTAssertEqualObjects (set, ([NSSet setWithObjects: @"A", @"B", @"C", nil]));
}


- (void) test13ArrayCollectD
{
    NSArray *array = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    NSDictionary *dict = (id) [[array BX_CollectD] uppercaseString];
    XCTAssertEqualObjects (dict, ([NSDictionary dictionaryWithObjectsAndKeys:
                                   @"a", @"A",
                                   @"b", @"B",
                                   @"c", @"C",
                                   nil]));
}


- (void) test14SetCollectD
{
    NSSet *set = [NSSet setWithObjects: @"a", @"b", @"c", nil];
    NSDictionary *dict = (id) [[set BX_CollectD] uppercaseString];
    XCTAssertEqualObjects (dict, ([NSDictionary dictionaryWithObjectsAndKeys:
                                   @"a", @"A",
                                   @"b", @"B",
                                   @"c", @"C",
                                   nil]));
}


- (void) test15DictCollectD
{
    NSDictionary *dict1 = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"a", @"1",
                    @"b", @"2",
                    @"c", @"3",
                    nil];
    NSDictionary *dict2 = (id) [[dict1 BX_CollectD] uppercaseString];
    XCTAssertEqualObjects (dict2, ([NSDictionary dictionaryWithObjectsAndKeys:
                                    @"a", @"A",
                                    @"b", @"B",
                                    @"c", @"C",
                                    nil]));
}


- (void) test16ArrayCollectDK
{
    NSArray *array = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    NSDictionary *dict = (id) [[array BX_CollectDK] uppercaseString];
    XCTAssertEqualObjects (dict, ([NSDictionary dictionaryWithObjectsAndKeys:
                                   @"A", @"a",
                                   @"B", @"b",
                                   @"C", @"c",
                                   nil]));
}


- (void) test17SetCollectDK
{
    NSSet *set = [NSSet setWithObjects: @"a", @"b", @"c", nil];
    NSDictionary *dict = (id) [[set BX_CollectDK] uppercaseString];
    XCTAssertEqualObjects (dict, ([NSDictionary dictionaryWithObjectsAndKeys:
                                   @"A", @"a",
                                   @"B", @"b",
                                   @"C", @"c",
                                   nil]));
}


- (void) test18DictCollectDK
{
    NSDictionary *dict1 = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"a", @"1",
                    @"b", @"2",
                    @"c", @"3",
                    nil];
    NSDictionary *dict2 = (id) [[dict1 BX_CollectDK] uppercaseString];
    XCTAssertEqualObjects (dict2, ([NSDictionary dictionaryWithObjectsAndKeys:
                                    @"A", @"a",
                                    @"B", @"b",
                                    @"C", @"c",
                                    nil]));
}


- (void) test19ArrayVisit
{
    OCMockObject *mock = [OCMockObject mockForClass: [NSUserDefaults class]];
    [[mock expect] objectIsForcedForKey: @"a" inDomain: @"b"];
    
    NSArray *array = [NSArray arrayWithObject: @"a"];
    [[array BX_Visit: mock] objectIsForcedForKey: nil inDomain: @"b"];
    
    [mock verify];
}


- (void) test20ArrayVisit
{
    OCMockObject *mock = [OCMockObject mockForClass: [NSUserDefaults class]];
    [[mock expect] objectIsForcedForKey: @"a" inDomain: @"b"];
    
    NSSet *set = [NSSet setWithObject: @"a"];
    [[set BX_Visit: mock] objectIsForcedForKey: nil inDomain: @"b"];
    
    [mock verify];
}


- (void) test21DictVisit
{
    OCMockObject *mock = [OCMockObject mockForClass: [NSUserDefaults class]];
    [[mock expect] objectIsForcedForKey: @"a" inDomain: @"b"];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObject: @"a" forKey: @"1"];
    [[dict BX_Visit: mock] objectIsForcedForKey: nil inDomain: @"b"];
    
    [mock verify];
}


- (void) test22ArrayReverse
{
    NSArray *array = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    XCTAssertEqualObjects ([array BX_Reverse], ([NSArray arrayWithObjects: @"c", @"b", @"a", nil]));
}


- (void) test23DictKeyCollectD
{
    NSDictionary *dict1 = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"1", @"a",
                           @"2", @"b",
                           @"3", @"c",
                           nil];
    NSDictionary *dict2 = (id) [[dict1 BX_KeyCollectD] uppercaseString];
    XCTAssertEqualObjects (dict2, ([NSDictionary dictionaryWithObjectsAndKeys:
                                    @"1", @"A",
                                    @"2", @"B",
                                    @"3", @"C",
                                    nil]));
}


static int
SelectFunction (id object)
{
    int retval = 1;
    if ([object isEqual: @"b"])
        retval = 0;
    return retval;
}


- (void) test24ArraySelectFunction
{
    NSArray *array = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    XCTAssertEqualObjects ([array BX_SelectFunction: &SelectFunction], ([NSArray arrayWithObjects: @"a", @"c", nil]));
}


- (void) test25SetSelectFunction
{
    NSSet *set = [NSSet setWithObjects: @"a", @"b", @"c", nil];
    XCTAssertEqualObjects ([set BX_SelectFunction: &SelectFunction], ([NSSet setWithObjects: @"a", @"c", nil]));
}


- (void) test26ValueSelectFunction
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"a", @"1",
                          @"b", @"2",
                          @"c", @"3",
                          nil];
    XCTAssertEqualObjects ([dict BX_ValueSelectFunction: &SelectFunction], ([NSArray arrayWithObjects: @"a", @"c", nil]));
}


static int
SelectFunction2 (id object, void *arg)
{
    assert ([(__bridge id) arg isEqual: @"k"]);
    
    int retval = 1;
    if ([object isEqual: @"b"])
        retval = 0;
    return retval;
}


- (void) test27ArraySelectFunction
{
    NSArray *array = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
    XCTAssertEqualObjects ([array BX_SelectFunction: &SelectFunction2 argument: @"k"], ([NSArray arrayWithObjects: @"a", @"c", nil]));
}


- (void) test28SetSelectFunction
{
    NSSet *set = [NSSet setWithObjects: @"a", @"b", @"c", nil];
    XCTAssertEqualObjects ([set BX_SelectFunction: &SelectFunction2 argument: @"k"], ([NSSet setWithObjects: @"a", @"c", nil]));
}


- (void) test29ValueSelectFunction
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"a", @"1",
                          @"b", @"2",
                          @"c", @"3",
                          nil];
    XCTAssertEqualObjects ([dict BX_ValueSelectFunction: &SelectFunction2 argument: @"k"], ([NSArray arrayWithObjects: @"a", @"c", nil]));
}


@end
