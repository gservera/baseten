//
// BXHostResolverTests.m
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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

#import "BXHostResolverTests.h"
#import <BaseTen/BXHostResolver.h>
#import <OCMock/OCMock.h>


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
	
	SInt32 status = CFRunLoopRunInMode (kCFRunLoopDefaultMode, 5.0, FALSE);
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
	[self runResolverForNodename: @"karppinen.fi" useDefaultRunLoopMode: YES shouldFail: NO];
}


- (void) test04
{
	[self runResolverForNodename: @"karppinen.fi" useDefaultRunLoopMode: NO shouldFail: NO];
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
