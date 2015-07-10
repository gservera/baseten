//
// BXPredicateTests.m
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

#import "BXPredicateTests.h"
#import "MKCSenTestCaseAdditions.h"
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXDatabaseContextPrivate.h>
#import <BaseTen/BXPGInterface.h>
#import <BaseTen/BXPGQueryBuilder.h>
#import <BaseTen/BXPredicateVisitor.h>
#import <BaseTen/BXAttributeDescriptionPrivate.h>

#import <OCMock/OCMock.h>


@implementation BXPredicateTests
- (void) setUp
{
	[super setUp];
	
	mQueryBuilder = [[BXPGQueryBuilder alloc] init];
	
	BXDatabaseObjectModelStorage *storage = [[[BXDatabaseObjectModelStorage alloc] init] autorelease];
	BXDatabaseContext *ctx = [[[BXDatabaseContext alloc] init] autorelease];
	[ctx setDelegate: self];
	[ctx setDatabaseObjectModelStorage: storage];
	[ctx setDatabaseURI: [self databaseURI]];
	
	BXEntityDescription* entity = [[ctx databaseObjectModel] entityForTable: @"test" inSchema: @"public"];
	MKCAssertNotNil (entity);
	
	OCMockObject *entityMock = [OCMockObject partialMockForObject: entity];
	BXAttributeDescription *attr = [BXAttributeDescription attributeWithName: @"id" entity: (id) entityMock];
	[[[entityMock stub] andReturn: [NSDictionary dictionaryWithObject: attr forKey: @"id"]] attributesByName];
	  
	[mQueryBuilder addPrimaryRelationForEntity: (id) entityMock];
	
	BXPGInterface* interface = (id)[ctx databaseInterface];
	[interface prepareForConnecting];
	BXPGTransactionHandler* handler = (id)[interface transactionHandler];
	[handler prepareForConnecting];
	mConnection = [[handler connection] retain];
}


- (void) tearDown
{
	[mQueryBuilder release];
	[mConnection release];
	[super tearDown];
}


- (void) testAddition
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"1 + 2 == 3"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 = ($2 + $3)");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects: [NSNumber numberWithInt: 3], [NSNumber numberWithInt: 1], [NSNumber numberWithInt: 2], nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testSubtraction
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"3 - 2 == 1"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 = ($2 - $3)");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects: [NSNumber numberWithInt: 1], [NSNumber numberWithInt: 3], [NSNumber numberWithInt: 2], nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testBegins
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"'foobar' BEGINSWITH 'foo'"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 ~~ (regexp_replace ($2, '([%_\\\\])', '\\\\\\1', 'g') || '%')");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects: @"foobar", @"foo", nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testEndsCase
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"'foobar' ENDSWITH[c] 'b%a_r'"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 ~~* ('%' || regexp_replace ($2, '([%_\\\\])', '\\\\\\1', 'g'))");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects: @"foobar", @"b%a_r", nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testBetween
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"2 BETWEEN {1, 3}"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"ARRAY [$1,$2] OPERATOR (\"baseten\".<<>>) $3");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects:
						 [NSNumber numberWithInt: 1],
						 [NSNumber numberWithInt: 3],
						 [NSNumber numberWithInt: 2],
						 nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testGt
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"1 < 2"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 > $2");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects:
						 [NSNumber numberWithInt: 2],
						 [NSNumber numberWithInt: 1],
						 nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testContains
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"{1, 2, 3} CONTAINS 2"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 = ANY (ARRAY [$2,$3,$4])");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects:
						 [NSNumber numberWithInt: 2],
						 [NSNumber numberWithInt: 1],
						 [NSNumber numberWithInt: 2],
						 [NSNumber numberWithInt: 3],
						 nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testIn
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"2 IN {1, 2, 3}"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 = ANY (ARRAY [$2,$3,$4])");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects:
						 [NSNumber numberWithInt: 2],
						 [NSNumber numberWithInt: 1],
						 [NSNumber numberWithInt: 2],
						 [NSNumber numberWithInt: 3],
						 nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testIn2
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"'bb' IN 'aabbccdd'"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"(0 != position ($1 in $2))");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects: @"bb", @"aabbccdd", nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testIn3
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"'bb' IN[c] 'aabbccdd'"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 ~~* ('%' || regexp_replace ($2, '([%_\\\\])', '\\\\\\1', 'g') || '%')");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects: @"aabbccdd", @"bb", nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testAndOr
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"1 < 2 AND (2 < 3 OR 4 > 5)"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"($1 > $2 AND ($3 > $4 OR $5 < $6))");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects:
						 [NSNumber numberWithInt: 2],
						 [NSNumber numberWithInt: 1],
						 [NSNumber numberWithInt: 3],
						 [NSNumber numberWithInt: 2],
						 [NSNumber numberWithInt: 5],
						 [NSNumber numberWithInt: 4],
						 nil];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testNull
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"1 == %@", [NSNull null]];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 IS NULL");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObject: [NSNumber numberWithInt: 1]];
	MKCAssertEqualObjects (parameters, expected);
}


- (void) testAdditionWithKeyPath
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"1 + id == 2"];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate 
															entity: [[mQueryBuilder primaryRelation] entity] 
														connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 = ($2 + te1.\"id\")");
	NSArray* parameters = [mQueryBuilder parameters];
	NSArray* expected = [NSArray arrayWithObjects: [NSNumber numberWithInteger: 2], [NSNumber numberWithInteger: 1], nil];
	MKCAssertEqualObjects (parameters, expected);	
}


- (void) testDiacriticInsensitivity
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"'a' LIKE[cd] 'b'"];
	[mQueryBuilder setQueryType: kBXPGQueryTypeSelect];
	NSString* whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"(true)");
	NSArray* parameters = [mQueryBuilder parameters];
	MKCAssertEqualObjects (parameters, [NSArray array]);
}


- (void) testCustomExpression
{
	BXVerbatimExpressionValue *val = [BXVerbatimExpressionValue valueWithString: @"SESSION_USER"];
	NSExpression *lhs = [NSExpression expressionForConstantValue: val];
	NSExpression *rhs = [NSExpression expressionForConstantValue: @"tsnorri"];
	
	NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression: lhs
																rightExpression: rhs
																	   modifier: NSDirectPredicateModifier
																		   type: NSEqualToPredicateOperatorType
																		options: 0];
	
	[mQueryBuilder setQueryType: kBXPGQueryTypeSelect];
	NSString *whereClause = [mQueryBuilder whereClauseForPredicate: predicate entity: nil connection: mConnection].p_where_clause;
	MKCAssertEqualObjects (whereClause, @"$1 = SESSION_USER");
	NSArray *parameters = [mQueryBuilder parameters];
	MKCAssertEqualObjects (parameters, [NSArray arrayWithObject: @"tsnorri"]);
}
@end
