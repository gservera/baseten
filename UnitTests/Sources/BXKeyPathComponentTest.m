//
// BXKeyPathComponentTest.m
// BaseTen
//
// Copyright 2008-2010 Marko Karppinen & Co. LLC.
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

#import "BXKeyPathComponentTest.h"
#import "MKCSenTestCaseAdditions.h"
#import <BaseTen/BXKeyPathParser.h>


@implementation BXKeyPathComponentTest
- (void) testKeyPath
{
	NSString* keyPath = @"aa.bb.cc";
	NSArray* components = BXKeyPathComponents (keyPath);
	MKCAssertEqualObjects (components, ([NSArray arrayWithObjects: @"aa", @"bb", @"cc", nil]));
}

- (void) testQuotedKeyPAth
{
	NSString* keyPath = @"\"aa.bb\".cc";
	NSArray* components = BXKeyPathComponents (keyPath);
	MKCAssertEqualObjects (components, ([NSArray arrayWithObjects: @"aa.bb", @"cc", nil]));
}

- (void) testSingleComponent
{
	NSString* keyPath = @"aa";
	NSArray* components = BXKeyPathComponents (keyPath);
	MKCAssertEqualObjects (components, ([NSArray arrayWithObjects: @"aa", nil]));
}

- (void) testRecurringFullStops
{
	NSString* keyPath = @"aa..bb";
	MKCAssertThrowsSpecificNamed (BXKeyPathComponents (keyPath), NSException, NSInvalidArgumentException);
}

- (void) testEndingFullStop
{
	NSString* keyPath = @"aa.";
	MKCAssertThrowsSpecificNamed (BXKeyPathComponents (keyPath), NSException, NSInvalidArgumentException);
}

- (void) testBeginningFullStop
{
	NSString* keyPath = @".aa";
	MKCAssertThrowsSpecificNamed (BXKeyPathComponents (keyPath), NSException, NSInvalidArgumentException);
}
@end
