//
// BXDelegateProxyTests.m
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

#import <BaseTen/BXDelegateProxy.h>
#import <OCMock/OCMock.h>
#import "BXDelegateProxyTests.h"


@implementation BXDelegateProxyTests
- (void) setUp
{
	mDefaultImpl = [[OCMockObject mockForClass: [NSNumber class]] retain];
	mDelegateImpl = [[OCMockObject mockForClass: [NSValue class]] retain];
	
	mDelegateProxy = [[BXDelegateProxy alloc] initWithDelegateDefaultImplementation: mDefaultImpl];
	[mDelegateProxy setDelegateForBXDelegateProxy: mDelegateImpl];
}


- (void) tearDown
{
	[mDelegateProxy release];
	[mDelegateImpl release];
	[mDefaultImpl release];
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
