//
// PGTSInvocationRecorderTests.m
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

#import "PGTSInvocationRecorderTests.h"
#import "MKCSenTestCaseAdditions.h"
#import <OCMock/OCMock.h>
#import <BaseTen/PGTSInvocationRecorder.h>


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
	MKCAssertEquals (s, [invocation target]);
	MKCAssertTrue (0 == strcmp ((const char *) selector, (const char *) [invocation selector]));
	MKCAssertEqualObjects ([s methodSignatureForSelector: selector], [invocation methodSignature]);
}


- (void) test2
{
	NSString *s = @"a";
	NSInvocation *invocation = nil;
	[[PGTSInvocationRecorder recordWithTarget: s outInvocation: &invocation] uppercaseString];
	
	SEL selector = @selector (uppercaseString);
	MKCAssertEquals (s, [invocation target]);
	MKCAssertTrue (0 == strcmp ((const char *) selector, (const char *) [invocation selector]));
	MKCAssertEqualObjects ([s methodSignatureForSelector: selector], [invocation methodSignature]);
}


- (void) test3
{
	NSString *s = @"a";
	NSCharacterSet *set = [NSCharacterSet alphanumericCharacterSet];
	NSStringCompareOptions opts = NSCaseInsensitiveSearch;
	NSInvocation *invocation = nil;
	[[PGTSInvocationRecorder recordWithTarget: s outInvocation: &invocation] rangeOfCharacterFromSet: set options: opts];
	
	SEL selector = @selector (rangeOfCharacterFromSet:options:);
	MKCAssertEquals (s, [invocation target]);
	MKCAssertTrue (0 == strcmp ((const char *) selector, (const char *) [invocation selector]));
	MKCAssertEqualObjects ([s methodSignatureForSelector: selector], [invocation methodSignature]);
	
	NSCharacterSet *invocationSet = nil;
	NSStringCompareOptions invocationOpts = 0;
	[invocation getArgument: &invocationSet atIndex: 2];
	[invocation getArgument: &invocationOpts atIndex: 3];
	MKCAssertEquals (set, invocationSet);
	MKCAssertEquals (opts, invocationOpts);
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
