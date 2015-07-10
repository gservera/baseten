//
// BXPGQueryBuilder.m
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

#import "BXPGQueryBuilder.h"
#import "BXPredicateVisitor.h"
#import "BXPGConstantParameterMapper.h"
#import "BXPGRelationAliasMapper.h"
#import "BXPGInterface.h"
#import "BXDatabaseContextPrivate.h"
#import "BXPGTransactionHandler.h"
#import "BXLogger.h"
#import "BXPGFromItem.h"


@implementation BXPGQueryBuilder
- (id) init
{
	if ((self = [super init]))
	{
		mPredicateVisitor = [[BXPGPredicateVisitor alloc] init];
		mRelationMapper = [[BXPGRelationAliasMapper alloc] init];
		
		[mPredicateVisitor setRelationAliasMapper: mRelationMapper];
	}
	return self;
}

- (void) dealloc
{
	[mPredicateVisitor release];
	[mRelationMapper release];
	[super dealloc];
}

- (BXPGFromItem *) primaryRelation
{
	return mPrimaryRelation;
}

- (void) setPrimaryRelation: (BXPGFromItem *) fromItem
{
	if (mPrimaryRelation != fromItem)
	{
		[mPrimaryRelation release];
		mPrimaryRelation = [fromItem retain];
	}
}

- (void) addPrimaryRelationForEntity: (BXEntityDescription *) entity
{
	ExpectV (entity);
	ExpectV (mRelationMapper);
	BXPGFromItem* fromItem = [mRelationMapper addPrimaryRelationForEntity: entity];
	[self setPrimaryRelation: fromItem];
}

- (NSString *) addParameter: (id) value
{
	return [[mPredicateVisitor constantParameterMapper] addParameter: value];
}

- (NSArray *) parameters
{
	return [[mPredicateVisitor constantParameterMapper] parameters];
}

- (NSString *) fromClause
{
	Expect (mQueryType);
	NSString* retval = nil;
	
	switch (mQueryType) 
	{
		case kBXPGQueryTypeSelect:
			retval = [mRelationMapper fromClauseForSelect];
			break;
			
		case kBXPGQueryTypeUpdate:
		case kBXPGQueryTypeDelete:
			retval = [mRelationMapper fromOrUsingClause];
			break;
			
		case kBXPGQueryTypeNone:
		default:
			break;
	}
	return retval;
}

- (NSString *) fromClauseForSelect
{
	return [mRelationMapper fromClauseForSelect];
}

- (NSString *) target
{
	return [mRelationMapper target];
}

- (struct bx_predicate_st) whereClauseForPredicate: (NSPredicate *) predicate 
													object: (BXDatabaseObject *) object 
{
	BXDatabaseContext* ctx = [object databaseContext];
	BXPGInterface* interface = (id) [ctx databaseInterface];
	BXPGTransactionHandler* transactionHandler = [interface transactionHandler];
	PGTSConnection* connection = [transactionHandler connection];
	
	[mPredicateVisitor setObject: object];
	[mPredicateVisitor setEntity: [object entity]];
	[mPredicateVisitor setConnection: connection];
	[mPredicateVisitor setQueryType: mQueryType];
	return [mPredicateVisitor beginWithPredicate: predicate];
}

- (struct bx_predicate_st) whereClauseForPredicate: (NSPredicate *) predicate 
													entity: (BXEntityDescription *) entity 
												connection: (PGTSConnection *) connection
{
	[mPredicateVisitor setObject: nil];
	[mPredicateVisitor setEntity: entity];
	[mPredicateVisitor setConnection: connection];
	[mPredicateVisitor setQueryType: mQueryType];
	return [mPredicateVisitor beginWithPredicate: predicate];
}

- (void) reset
{
	mQueryType = kBXPGQueryTypeNone;
	[mRelationMapper resetAll];
	[[mPredicateVisitor constantParameterMapper] reset];
}

- (void) setQueryType: (enum BXPGQueryType) queryType
{
	mQueryType = queryType;
}
@end
