//
// BXDatabaseObjectTests.m
// BaseTen
//
// Copyright 2009-2010 Marko Karppinen & Co. LLC.
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

#import "BXDatabaseObjectTests.h"
#import "MKCSenTestCaseAdditions.h"
#import <OCMock/OCMock.h>

#import <BaseTen/BaseTen.h>
#import <BaseTen/BXDatabaseObjectPrivate.h>
#import <BaseTen/BXDatabaseContextPrivate.h>


@interface BXAttributeDescriptionPlaceholder : NSObject
{
    @public
    NSString* mName;
    BOOL mIsPkey;
    BOOL mIsOptional;
}
@end

@implementation BXAttributeDescriptionPlaceholder
- (void) dealloc
{
    [mName release];
    [super dealloc];
}
- (NSString *) name
{
    return mName;
}
- (NSComparisonResult) compare: (id) anObject
{
    return [mName compare: anObject];
}
- (BOOL) isPrimaryKey
{
    return mIsPkey;
}
- (BOOL) isOptional
{
    return mIsOptional;
}
@end


@implementation BXDatabaseObjectTests
- (void) setUp
{
	[super setUp];
	
    BXAttributeDescriptionPlaceholder* idDesc = [[[BXAttributeDescriptionPlaceholder alloc] init] autorelease];
    idDesc->mName = @"id";
    idDesc->mIsPkey = YES;
    idDesc->mIsOptional = NO;
    
    BXAttributeDescriptionPlaceholder* keyDesc = [[[BXAttributeDescriptionPlaceholder alloc] init] autorelease];
    keyDesc->mName = @"key";
    keyDesc->mIsPkey = NO;
    keyDesc->mIsOptional = YES;
    
    mContext = [OCMockObject niceMockForClass: [BXDatabaseContext class]];
    [[[mContext stub] andReturnValue: [NSNumber numberWithBool: YES]] registerObject: mObject];

    mEntity = [OCMockObject niceMockForClass: [BXEntityDescription class]];
    [[[mEntity stub] andReturn: [NSArray arrayWithObject: idDesc]] primaryKeyFields];
    [[[mEntity stub] andReturn: [NSDictionary dictionaryWithObjectsAndKeys:
        idDesc, @"id",
        keyDesc, @"key",
        nil]] attributesByName];
    [[[mEntity stub] andReturnValue: [NSNumber numberWithBool: YES]] isValidated];
    
    mObject = [[BXDatabaseObject alloc] init];
    MKCAssertNotNil (mObject);
    [mObject setCachedValue: @"value" forKey: @"key"];
    [mObject setCachedValue: [NSNumber numberWithInt: 1] forKey: @"id"];
}

- (void) tearDown
{
    [mContext verify];
    [mEntity verify];    
    
    [mObject release];
	
	[super tearDown];
}

- (void) testCachedValue
{    
    MKCAssertEqualObjects (@"value", [mObject cachedValueForKey: @"key"]);
}
@end
