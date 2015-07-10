//
//  BXHostResolverTests.m
//  BaseTen
//
//  Created by Guillem on 12/9/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <BaseTen/BXHostResolver.h>
#import <OCMock/OCMock.h>

@interface BXHostResolverTests : XCTestCase

@end

@implementation BXHostResolverTests

- (void) runResolverForNodename: (NSString *) nodename useDefaultRunLoopMode: (BOOL) useDefaultMode shouldFail: (BOOL) shouldFail
{
    BXHostResolver *resolver = [[BXHostResolver alloc] init];
    
    OCMockObject *mock = [OCMockObject mockForProtocol: @protocol (BXHostResolverDelegate)];
    // FIXME: use a HC matcher for addresses and error in the expected case.
    if (shouldFail)
    {
        [[mock expect] hostResolverDidFail: resolver error: OCMOCK_ANY];
        NSException *exc = [NSException exceptionWithName: NSInternalInconsistencyException
                                                   reason: @"Expected resolver to fail."
                                                 userInfo: nil];
        [[[mock stub] andThrow: exc] hostResolverDidSucceed: resolver addresses: OCMOCK_ANY];
    }
    else
    {
        [[mock expect] hostResolverDidSucceed: resolver addresses: OCMOCK_ANY];
        NSException *exc = [NSException exceptionWithName: NSInternalInconsistencyException
                                                   reason: @"Expected resolver to succeed."
                                                 userInfo: nil];
        [[[mock stub] andThrow: exc] hostResolverDidFail: resolver error: OCMOCK_ANY];
    }
    
    CFRunLoopRef runLoop = CFRunLoopGetCurrent ();
    
    [resolver setRunLoop: runLoop];
    [resolver setRunLoopMode: (id) (useDefaultMode ? kCFRunLoopDefaultMode : kCFRunLoopCommonModes)];
    [resolver setDelegate: (id <BXHostResolverDelegate>) mock];
    [resolver resolveHost: nodename];
    
    SInt32 status = CFRunLoopRunInMode (kCFRunLoopDefaultMode, 3.0, FALSE);
    status = 0;
    [mock verify];
}


- (void) test01
{
    [self runResolverForNodename: @"langley.macsinracks.net" useDefaultRunLoopMode: YES shouldFail: NO];
}


- (void) test02
{
    [self runResolverForNodename: @"langley.macsinracks.net" useDefaultRunLoopMode: NO shouldFail: NO];
}


- (void) test03
{
    [self runResolverForNodename: @"aurumcode.com" useDefaultRunLoopMode: YES shouldFail: NO];
}


- (void) test04
{
    [self runResolverForNodename: @"aurumcode.com" useDefaultRunLoopMode: NO shouldFail: NO];
}


- (void) test05
{
    [self runResolverForNodename: @"karppinen.invalid" useDefaultRunLoopMode: YES shouldFail: YES];
}


- (void) test06
{
    [self runResolverForNodename: @"karppinen.invalid" useDefaultRunLoopMode: NO shouldFail: YES];
}


- (void) test07
{
    [self runResolverForNodename: @"127.0.0.1" useDefaultRunLoopMode: YES shouldFail: NO];
}


- (void) test08
{
    [self runResolverForNodename: @"127.0.0.1" useDefaultRunLoopMode: NO shouldFail: NO];
}


- (void) test09
{
    [self runResolverForNodename: @"::1" useDefaultRunLoopMode: YES shouldFail: NO];
}


- (void) test10
{
    [self runResolverForNodename: @"::1" useDefaultRunLoopMode: YES shouldFail: NO];
}

@end
