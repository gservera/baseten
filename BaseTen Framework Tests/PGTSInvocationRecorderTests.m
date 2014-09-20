//
//  PGTSInvocationRecorderTests.m
//  BaseTen
//
//  Created by Guillem on 8/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <BaseTen/PGTSInvocationRecorder.h>

@interface PGTSInvocationRecorderTests : XCTestCase

@end

@protocol PGTSInvocationRecorderTestCallback
- (void) myCallback: (NSInvocation *) invocation userInfo: (id) userInfo;
@end



@implementation PGTSInvocationRecorderTests
- (void) test1
{
    NSString *s = @"a";
    PGTSInvocationRecorder *recorder = [[PGTSInvocationRecorder alloc] init];
    [recorder setTarget: s];
    [[recorder record] uppercaseString];
    
    NSInvocation *invocation = [recorder invocation];
    SEL selector = @selector (uppercaseString);
    XCTAssertEqual(s, [invocation target]);
    XCTAssertTrue(0 == strcmp (sel_getName(selector), sel_getName([invocation selector])));
    XCTAssertEqualObjects ([s methodSignatureForSelector: selector], [invocation methodSignature]);
}


- (void) test2
{
    NSString *s = @"a";
    NSInvocation *invocation = nil;
    [[PGTSInvocationRecorder recordWithTarget: s outInvocation: &invocation] uppercaseString];
    
    SEL selector = @selector (uppercaseString);
    XCTAssertEqual (s, [invocation target]);
    XCTAssertTrue (0 == strcmp (sel_getName(selector), sel_getName([invocation selector])));
    XCTAssertEqualObjects ([s methodSignatureForSelector: selector], [invocation methodSignature]);
}


- (void) test3
{
    NSString *s = @"a";
    NSCharacterSet *set = [NSCharacterSet alphanumericCharacterSet];
    NSStringCompareOptions opts = NSCaseInsensitiveSearch;
    NSInvocation *invocation = nil;
    [[PGTSInvocationRecorder recordWithTarget: s outInvocation: &invocation] rangeOfCharacterFromSet: set options: opts];
    
    SEL selector = @selector (rangeOfCharacterFromSet:options:);
    XCTAssertEqual(s, [invocation target]);
    XCTAssertTrue (0 == strcmp (sel_getName(selector), sel_getName([invocation selector])));
    XCTAssertEqualObjects ([s methodSignatureForSelector: selector], [invocation methodSignature]);
    
    NSCharacterSet *invocationSet = nil;
    NSStringCompareOptions invocationOpts = 0;
    [invocation getArgument: &invocationSet atIndex: 2];
    [invocation getArgument: &invocationOpts atIndex: 3];
    XCTAssertEqual(set, invocationSet);
    XCTAssertEqual(opts, invocationOpts);
}


- (void) test4
{
    NSString *a = @"a";
    NSString *b = @"b";
    OCMockObject *callbackTarget = [OCMockObject mockForProtocol: @protocol (PGTSInvocationRecorderTestCallback)];
    
    PGTSCallbackInvocationRecorder *recorder = [[[PGTSCallbackInvocationRecorder alloc] init] autorelease];
    [recorder setCallback: @selector (myCallback:userInfo:)];
    [recorder setCallbackTarget: callbackTarget];
    [recorder setUserInfo: b];
    
    [[callbackTarget expect] myCallback: OCMOCK_ANY userInfo: b];
    [[recorder recordWithTarget: a] uppercaseString];
}
@end
