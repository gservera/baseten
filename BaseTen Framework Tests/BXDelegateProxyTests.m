//
//  BXDelegateProxyTests.m
//  BaseTen
//
//  Created by Guillem on 9/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <BaseTen/BXDelegateProxy.h>

@interface BXDelegateProxyTests : XCTestCase
{
    id mDelegateProxy;
    id mDelegateImpl;
    id mDefaultImpl;
}
@end

@implementation BXDelegateProxyTests

- (void) setUp
{
    mDefaultImpl = [OCMockObject mockForClass: [NSNumber class]];
    mDelegateImpl = [OCMockObject mockForClass: [NSValue class]];
    
    mDelegateProxy = [[BXDelegateProxy alloc] initWithDelegateDefaultImplementation: mDefaultImpl];
    [mDelegateProxy setDelegateForBXDelegateProxy: mDelegateImpl];
}


- (void) test1
{
    [[mDelegateImpl expect] nonretainedObjectValue];
    [mDelegateProxy nonretainedObjectValue];
    [mDelegateImpl verify];
}


- (void) test2
{
    [[mDefaultImpl expect] stringValue];
    [mDelegateProxy stringValue];
    [mDelegateImpl verify];
}

@end
