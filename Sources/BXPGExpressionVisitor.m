//
// BXPGExpressionVisitor.m
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

#import "BXHOM.h"
#import "BXAttributeDescription.h"
#import "BXPGFromItem.h"
#import "BXManyToManyRelationshipDescription.h"
#import "BXPGAdditions.h"
#import "BXEnumerate.h"
#import "BXLogger.h"


@implementation BXPGExpressionVisitor
- (id) init
{
	if ((self = [super init]))
	{
		mSQLExpression = [[NSMutableString alloc] init];
		mComponents = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[mSQLExpression release];
	[mComponents release];
	[mConnection release];
	[super dealloc];
}

- (void) reset
{
	[mComponents removeAllObjects];
	[mSQLExpression setString: @""];
}

- (void) setComponents: (NSArray *) anArray
{
	[mComponents removeAllObjects];
	[mComponents addObjectsFromArray: anArray];
}

- (PGTSConnection *) connection
{
	return mConnection;
}

- (void) setConnection: (PGTSConnection *) conn
{
	if (conn != mConnection)
	{
		[mConnection release];
		mConnection = [conn retain];
	}
}

- (NSString *) beginWithKeyPath: (NSArray *) components
{		
	BXAssertValueReturn ([self relationAliasMapper], nil, @"Expected to have a relation alias mapper.");
	BXAssertValueReturn ([[self relationAliasMapper] primaryRelation], nil, @"Expected to have a primary relation.");
	
	[self reset];
	[self setComponents: components];
	
	BXEnumerate (currentComponent, e, [components objectEnumerator])
		[currentComponent BXPGVisitKeyPathComponent: self];		
	
	return [[mSQLExpression copy] autorelease];
}
@end


@implementation BXPGExpressionVisitor (BXPGExpressionVisitor)
- (void) visitCountAggregate: (BXPGSQLFunction *) sqlFunction
{
	//We only need the first relationship for this.
	BXPGRelationAliasMapper* mapper = [self relationAliasMapper];
	[mapper resetCurrent];
	BXRelationshipDescription* rel = [mComponents objectAtIndex: 0];
	BXPGFromItem* leftJoin = [mapper addFromItemForRelationship: rel];
	[mSQLExpression setString: @""];
	[mSQLExpression appendFormat: @"COUNT (%@.*)", [leftJoin alias]];
}

- (void) visitArrayCountFunction: (BXPGSQLFunction *) sqlFunction
{
	[mSQLExpression setString: [NSString stringWithFormat: @"array_upper (%@, 1)", mSQLExpression]];
}

- (void) visitAttribute: (BXAttributeDescription *) attr
{
	BXPGFromItem* item = nil;
	BXPGFromItem* lastItem = [[self relationAliasMapper] previousFromItem];
	BXPGFromItem* primaryRelation = [[self relationAliasMapper] primaryRelation];
	if (lastItem && [[attr entity] isEqual: [lastItem entity]])
		item = lastItem;
	else if ([[attr entity] isEqual: [primaryRelation entity]])
		item = primaryRelation;
	else
	{
		[NSException raise: NSInternalInconsistencyException format: 
		 @"Tried to add an attribute the entity of which wasn't found in from items."];
	}
	
	[mSQLExpression setString: [item alias]];
	[mSQLExpression appendString: @".\""];
	[mSQLExpression appendString: [attr name]];
	[mSQLExpression appendString: @"\""];
}

- (void) visitRelationship: (BXRelationshipDescription *) rel
{
	[[self relationAliasMapper] addFromItemForRelationship: rel];
}

- (void) visitArrayAccumFunction: (BXPGSQLFunction *) sqlFunction
{
	[mSQLExpression setString: [NSString stringWithFormat: @"\"baseten\".array_accum (%@)", mSQLExpression]];
}
@end
