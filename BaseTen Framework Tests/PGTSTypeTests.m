//
// PGTSTypeTests.m
// BaseTen
//
// Copyright 2009 Marko Karppinen & Co. LLC.
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

#import <BaseTen/PGTSConnection.h>
#import <BaseTen/PGTSResultSet.h>
#import <BaseTen/PGTSConstants.h>
#import "BXDatabaseTestCase.h"

@interface PGTSTypeTests : BXDatabaseTestCase{
    PGTSConnection* mConnection;
}
@end

@implementation PGTSTypeTests
- (void) setUp
{
	[super setUp];
	NSDictionary* connectionDictionary = [self connectionDictionary];
	mConnection = [[PGTSConnection alloc] init];
	BOOL status = [mConnection connectSync: connectionDictionary];
	XCTAssertTrue (status, @"%@",[[mConnection connectionError] description]);
}

- (void) tearDown
{
	[mConnection disconnect];
	[super tearDown];
}

- (void) testInt2
{
	PGTSResultSet* res = [mConnection executeQuery: @"SELECT * FROM int2_test"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	[res advanceRow];
	NSNumber* value = [res valueForKey: @"value"];
	XCTAssertNotNil (value);	
	
	SInt16 i = 0;
	XCTAssertTrue (CFNumberGetValue ((CFNumberRef) value, kCFNumberSInt16Type, &i));
	XCTAssertTrue (12 == i);
}

- (void) testInt4
{
	PGTSResultSet* res = [mConnection executeQuery: @"SELECT * FROM int4_test"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	[res advanceRow];
	NSNumber* value = [res valueForKey: @"value"];
	XCTAssertNotNil (value);	
	
	SInt32 i = 0;
	XCTAssertTrue (CFNumberGetValue ((CFNumberRef) value, kCFNumberSInt32Type, &i));
	XCTAssertTrue (14 == i);
}

- (void) testInt8
{
	PGTSResultSet* res = [mConnection executeQuery: @"SELECT * FROM int8_test"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	[res advanceRow];
	NSNumber* value = [res valueForKey: @"value"];
	XCTAssertNotNil (value);	
	
	SInt64 i = 0;
	XCTAssertTrue (CFNumberGetValue ((CFNumberRef) value, kCFNumberSInt64Type, &i));
	XCTAssertTrue (16 == i);
}

- (void) testText
{
	PGTSResultSet* res = [mConnection executeQuery: @"SELECT * FROM text_test"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	[res advanceRow];
	NSString* value = [res valueForKey: @"value"];
	XCTAssertNotNil (value);
	
	XCTAssertTrue (NSOrderedSame == [value compare: @"aàáâäå" options: 0]);
	XCTAssertTrue ([value isEqualToString: [@"aàáâäå" decomposedStringWithCanonicalMapping]]);
}

- (void) testPoint
{
	PGTSResultSet* res = [mConnection executeQuery: @"SELECT * FROM point_test"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	[res advanceRow];
	NSValue* value = [res valueForKey: @"value"];
	XCTAssertNotNil (value);
	
	NSPoint point = [value pointValue];
	XCTAssertTrue (NSEqualPoints (NSMakePoint (2.005, 10.0), point));
}

static inline int
f_eq (float a, float b)
{
	float aa = fabsf (a);
	float bb = fabsf (b);
	return (fabsf (aa - bb) <= (FLT_EPSILON * MAX (aa, bb)));
}

int d_eq (double a, double b)
{
    double aa = fabs (a);
    double bb = fabs (b);
    return (fabs (aa - bb) <= (FLT_EPSILON * MAX (aa, bb)));
}

- (void) testFloat4
{
	XCTAssertTrue (4 == sizeof (float));
	
	PGTSResultSet* res = [mConnection executeQuery: @"SELECT * FROM float4_test"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	[res advanceRow];
	NSNumber* value = [res valueForKey: @"value"];
	XCTAssertNotNil (value);	

	float f = 2.71828;
	XCTAssertTrue (f_eq (f, [value floatValue]));
}

- (void) testFloat8
{
	XCTAssertTrue (8 == sizeof (double));
	
	PGTSResultSet* res = [mConnection executeQuery: @"SELECT * FROM float8_test"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	[res advanceRow];
	NSNumber* value = [res valueForKey: @"value"];
	XCTAssertNotNil (value);
	
	double d = 2.71828;
	XCTAssertTrue (d_eq (d, [value doubleValue]));
}

- (void) testXMLDocument
{
	PGTSResultSet* res = [mConnection executeQuery: @"SELECT * FROM xml_document_test"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	while (([res advanceRow]))
	{
		NSXMLDocument* value = [res valueForKey: @"value"];
		XCTAssertNotNil (value);
		XCTAssertTrue ([value isKindOfClass: [NSXMLDocument class]]);
	}
}

- (void) testXMLFragment
{
	PGTSResultSet* res = [mConnection executeQuery: @"SELECT * FROM xml_fragment_test"];
	XCTAssertTrue ([res querySucceeded], @"%@",[[res error] description]);
	
	while (([res advanceRow]))
	{
		NSXMLDocument* value = [res valueForKey: @"value"];
		XCTAssertNotNil (value);
		XCTAssertTrue ([value isKindOfClass: [NSData class]]);
	}
}
@end
