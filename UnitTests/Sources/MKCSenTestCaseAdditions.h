//
// MKCSenTestCaseAdditions.h
// BaseTen
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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

/*!
    Some macros which extend SenTestCase.h with assertion methods which don't require a description string.
    Adds also a macro to run the current runloop in default mode until some condition becomes FALSE or timeout occurs.
*/

#import <SenTestingKit/SenTestingKit.h>

#define MKC_ASSERT_DESCRIPTION @"Assertion failed"

#define MKCAssertNil(a1) STAssertNil(a1, MKC_ASSERT_DESCRIPTION)
#define MKCAssertNotNil(a1) STAssertNotNil(a1, MKC_ASSERT_DESCRIPTION)
#define MKCAssertTrue(expression) STAssertTrue(expression, MKC_ASSERT_DESCRIPTION)
#define MKCAssertFalse(expression) STAssertFalse(expression, MKC_ASSERT_DESCRIPTION)
#define MKCAssertEqualObjects(a1, a2) STAssertEqualObjects(a1, a2, MKC_ASSERT_DESCRIPTION)
#define MKCAssertEquals(a1, a2) STAssertEquals(a1, a2, MKC_ASSERT_DESCRIPTION)
#define MKCAssertEqualsWithAccuracy(left, right, accuracy) STAssertEqualsWithAccuracy(left, right, accuracy, MKC_ASSERT_DESCRIPTION)
#define MKCAssertThrows(expression) STAssertThrows(expression, MKC_ASSERT_DESCRIPTION)
#define MKCAssertThrowsSpecific(expression, specificException) STAssertThrowsSpecific(expression, specificException, MKC_ASSERT_DESCRIPTION)
#define MKCAssertThrowsSpecificNamed(expr, specificException, aName) STAssertThrowsSpecificNamed(expr, specificException, aName, MKC_ASSERT_DESCRIPTION)
#define MKCAssertNoThrow(expression) STAssertNoThrow(expression, MKC_ASSERT_DESCRIPTION)
#define MKCAssertNoThrowSpecific(expression, specificException) STAssertNoThrowSpecific(expression, specificException, MKC_ASSERT_DESCRIPTION)
#define MKCAssertNoThrowSpecificNamed(expr, specificException, aName) STAssertNoThrowSpecificNamed(expr, specificException, aName, MKC_ASSERT_DESCRIPTION)
#define MKCFail() STFail(MKC_ASSERT_DESCRIPTION)
#define MKCAssertTrueNoThrow(expression) STAssertTrueNoThrow(expression, MKC_ASSERT_DESCRIPTION)
#define MKCAssertFalseNoThrow(expression) STAssertFalseNoThrow(expression, MKC_ASSERT_DESCRIPTION)

#define MKCRunLoopRunWithConditionAndTimeout(loopCondition, timeoutInSeconds) \
{ \
    NSDate *runLoopTimeout = [NSDate dateWithTimeIntervalSinceNow: timeoutInSeconds]; \
    while ((loopCondition) && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:runLoopTimeout]) \
    { \
        NSDate *currentDate = [NSDate date]; \
        if([currentDate compare:runLoopTimeout] != NSOrderedAscending) \
            break; \
    } \
}
