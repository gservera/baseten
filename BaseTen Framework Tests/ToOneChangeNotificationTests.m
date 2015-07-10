//
// ToOneChangeNotificationTests.h
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

#import <BaseTen/BaseTen.h>
#import <BaseTen/BXAttributeDescriptionPrivate.h>
#import "BXDatabaseTestCase.h"


static NSString* kObservingContext = @"ToOneChangeNotificationTestsObservingContext";

@interface ToOneChangeNotificationTests : BXDatabaseTestCase
{
    BXEntityDescription* mTest1;
    BXEntityDescription* mTest2;
    
    BXDatabaseObject* mA;
    BXDatabaseObject* mB1;
    BXDatabaseObject* mB2;
    
    NSInteger mReceivedForA;
    NSInteger mReceivedForB1;
    NSInteger mReceivedForB2;
}
@end


//In situations like A <-->> B and A <--> B database objects on 
//both (to-one) sides should post KVO change notifications.
@implementation ToOneChangeNotificationTests
- (void) setUp
{
	[super setUp];
	
	mA = nil;
	mB1 = nil;
	mB2 = nil;
	
	mReceivedForA = 0;
	mReceivedForB1 = 0;
	mReceivedForB2 = 0;
	
	[mContext connectSync: NULL];
	mTest1 = [[mContext databaseObjectModel] entityForTable: @"test1" inSchema: @"Fkeytest"];
	mTest2 = [[mContext databaseObjectModel] entityForTable: @"test2" inSchema: @"Fkeytest"];
}

- (void) testAttributeDependency
{
	NSDictionary* attributes = [mTest2 attributesByName];
	XCTAssertNotNil (attributes);
	BXAttributeDescription* attr = [attributes objectForKey: @"fkt1id"];
	XCTAssertNotNil (attr);
	NSSet* deps = [attr dependentRelationships];
	XCTAssertTrue (0 < [deps count]);
}


- (void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object change: (NSDictionary *) change context: (void *) context
{
    if (kObservingContext == context) 
	{
		if (mA == object)
			mReceivedForA++;
		else if (mB1 == object)
			mReceivedForB1++;
		else if (mB2 == object)
			mReceivedForB2++;
		else
			XCTAssertTrue (NO, @"Got a strange KVO notification.");
	}
	else 
	{
		[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
	}
}


//Get one object from test2 (a) and two from test1 (b1, b2). Replace a's reference to b1 with b2.
- (void) testOneToMany
{
	NSPredicate* p = [NSPredicate predicateWithFormat: @"id == 2"];
	NSArray* r1 = [mContext executeFetchForEntity: mTest1 withPredicate: p error: NULL];
	NSArray* r2 = [mContext executeFetchForEntity: mTest2 withPredicate: p error: NULL];
	
	mA = [r2 objectAtIndex: 0];
	mB1 = [mA primitiveValueForKey: @"test1"];
	mB2 = [r1 objectAtIndex: 0];

	XCTAssertNotNil (mA);
	XCTAssertNotNil (mB1);
	XCTAssertNotNil (mB2);
	XCTAssertFalse (mB1 == mB2);
	
	[mA addObserver: self forKeyPath: @"test1" options: 0 context: (__bridge void *)(kObservingContext)];
	[mB1 addObserver: self forKeyPath: @"test2" options: 0 context: (__bridge void *)(kObservingContext)];
	[mB2 addObserver: self forKeyPath: @"test2" options: 0 context: (__bridge void *)(kObservingContext)];
	
	XCTAssertEqual (0, mReceivedForA);
	XCTAssertEqual (0, mReceivedForB1);
	XCTAssertEqual (0, mReceivedForB2);
	
	[mA setPrimitiveValue: [NSNull null] forKey: @"fkt1id"];
	XCTAssertTrue (0 < mReceivedForA);
	XCTAssertTrue (0 < mReceivedForB1);
	XCTAssertEqual (0, mReceivedForB2);
	
	mReceivedForA = 0;
	mReceivedForB1 = 0;
	mReceivedForB2 = 0;
	
	[mA setPrimitiveValue: [NSNumber numberWithInteger: 2] forKey: @"fkt1id"];
	XCTAssertTrue (0 < mReceivedForA);
	XCTAssertEqual (0, mReceivedForB1);
	XCTAssertTrue (0 < mReceivedForB2);
	
	[mA removeObserver: self forKeyPath: @"test1"];
	[mB1 removeObserver: self forKeyPath: @"test2"];
	[mB2 removeObserver: self forKeyPath: @"test2"];
}


//Get one object from ototest1 (a) and two from ototest2 (b1, b2). Replace a's reference to b1 with b2.
- (void) testOneToOne
{
	NSPredicate* p1 = [NSPredicate predicateWithFormat: @"id == 1"];
	NSPredicate* p2 = [NSPredicate predicateWithFormat: @"id == 3"];
	BXEntityDescription* ototest1 = [[mContext databaseObjectModel] entityForTable: @"ototest1" inSchema: @"Fkeytest"];
	BXEntityDescription* ototest2 = [[mContext databaseObjectModel] entityForTable: @"ototest2" inSchema: @"Fkeytest"];
	NSArray* r1 = [mContext executeFetchForEntity: ototest1 withPredicate: p1 error: NULL];
	NSArray* r2 = [mContext executeFetchForEntity: ototest2 withPredicate: p2 error: NULL];
	
	mA = [r1 objectAtIndex: 0];
	mB1 = [mA primitiveValueForKey: @"ototest2"];
	mB2 = [r2 objectAtIndex: 0];
	
	XCTAssertNotNil (mA);
	XCTAssertNotNil (mB1);
	XCTAssertNotNil (mB2);
	XCTAssertFalse (mB1 == mB2);
	
	[mA addObserver: self forKeyPath: @"ototest2" options: 0 context: (__bridge void *)(kObservingContext)];
	[mB1 addObserver: self forKeyPath: @"ototest1" options: 0 context: (__bridge void *)(kObservingContext)];
	[mB2 addObserver: self forKeyPath: @"ototest1" options: 0 context: (__bridge void *)(kObservingContext)];
	
	XCTAssertEqual (0, mReceivedForA);
	XCTAssertEqual (0, mReceivedForB1);
	XCTAssertEqual (0, mReceivedForB2);

	[mB1 setPrimitiveValue: [NSNull null] forKey: @"r1"];
	XCTAssertTrue (0 < mReceivedForA);
	XCTAssertTrue (0 < mReceivedForB1);
	XCTAssertEqual (0, mReceivedForB2);
	
	mReceivedForA = 0;
	mReceivedForB1 = 0;
	mReceivedForB2 = 0;
	
	[mB2 setPrimitiveValue: [NSNumber numberWithInteger: 1] forKey: @"r1"];
	XCTAssertTrue (0 < mReceivedForA);
	XCTAssertEqual (0, mReceivedForB1);
	XCTAssertTrue (0 < mReceivedForB2);
	
	[mA removeObserver: self forKeyPath: @"ototest2"];
	[mB1 removeObserver: self forKeyPath: @"ototest1"];
	[mB2 removeObserver: self forKeyPath: @"ototest1"];
}
@end
