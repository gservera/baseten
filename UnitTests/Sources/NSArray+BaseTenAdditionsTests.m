//
// NSArray+BaseTenAdditionsTests.m
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

#import "NSArray+BaseTenAdditionsTests.h"
#import "MKCSenTestCaseAdditions.h"
#import <BaseTen/NSArray+BaseTenAdditions.h>


@implementation NSArray_BaseTenAdditionsTests
- (void) test1
{
	NSArray *a = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"SELF = %@", @"b"];
	
	NSMutableArray *others = [NSMutableArray array];
	NSArray *filtered = [a BXFilteredArrayUsingPredicate: predicate others: others substitutionVariables: nil];
	
	MKCAssertEqualObjects (filtered, [NSArray arrayWithObject: @"b"]);
	MKCAssertEqualObjects (others, ([NSArray arrayWithObjects: @"a", @"c", nil]));
}


- (void) test2
{
	NSArray *a = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"SELF = $MY_VAR"];
	
	NSMutableArray *others = [NSMutableArray array];
	NSDictionary *vars = [NSDictionary dictionaryWithObject: @"b" forKey: @"MY_VAR"];
	NSArray *filtered = [a BXFilteredArrayUsingPredicate: predicate others: others substitutionVariables: vars];
	
	MKCAssertEqualObjects (filtered, [NSArray arrayWithObject: @"b"]);
	MKCAssertEqualObjects (others, ([NSArray arrayWithObjects: @"a", @"c", nil]));
}
@end
