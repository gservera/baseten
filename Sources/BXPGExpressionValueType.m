//
// BXPGExpressionValueType.m
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


#import "BXPGExpressionValueType.h"
#import "BXPredicateVisitor.h"
#import "BXPGDatabaseObjectExpressionValueType.h"
#import "BXPGConstantExpressionValueType.h"
#import "PGTSFoundationObjects.h"


@implementation BXPGExpressionValueType
+ (id) valueTypeForObject: (id) value
{
	id retval = nil;
	if ([value isKindOfClass: [BXDatabaseObject class]])
	{
		retval = [BXPGDatabaseObjectExpressionValueType typeWithValue: value];
	}
	else
	{
		NSInteger cardinality = 0;
		//FIXME: perhaps we should check for multi-dimensionality.
		if ([value PGTSIsCollection])
			cardinality = 1;
		retval = [BXPGConstantExpressionValueType typeWithValue: value cardinality: cardinality];
	}
	return retval;
}

+ (id) type
{
	id retval = [[[self alloc] init] autorelease];
	return retval;
}

- (id) init
{
	if ([self class] == [BXPGExpressionValueType class])
		[self doesNotRecognizeSelector: _cmd];

	if ((self = [super init]))
	{
	}
	return self;
}

- (id) value
{
	return nil;
}

- (BOOL) isDatabaseObject
{
	return NO;
}

- (BOOL) hasRelationships
{
	return NO;
}

- (BOOL) isIdentityExpression
{
	return NO;
}

- (NSInteger) arrayCardinality
{
	return 0;
}

- (NSInteger) relationshipCardinality
{
	return 0;
}

- (NSString *) expressionSQL: (id <BXPGExpressionHandler>) visitor
{
	BXLogError (@"Tried to call -expressionSQL: for class %@, value %@", [self class], [self value]);
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}
@end
