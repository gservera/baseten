//
// BXPGRelationshipExpressionValueType.m
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


#import "BXPGRelationshipExpressionValueType.h"


@implementation BXPGRelationshipExpressionValueType
+ (id) typeWithValue: (id) value arrayCardinality: (NSInteger) cardinality relationshipCardinality: (NSInteger) rCardinality
	hasRelationships: (BOOL) hasRelationships;
{
	id retval = [[[self alloc] initWithValue: value arrayCardinality: cardinality 
					 relationshipCardinality: rCardinality hasRelationships: hasRelationships] autorelease];
	return retval;
}

- (id) initWithValue: (id) value arrayCardinality: (NSInteger) cardinality relationshipCardinality: (NSInteger) rCardinality
	hasRelationships: (BOOL) hasRelationships;
{
	if ([self class] == [BXPGRelationshipExpressionValueType class])
		[self doesNotRecognizeSelector: _cmd];
	
	if ((self = [super initWithValue: value cardinality: cardinality]))
	{
		mRelationshipCardinality = rCardinality;
		mHasRelationships = hasRelationships;
	}
	return self;
}

- (id) initWithValue: (id) value cardinality: (NSInteger) cardinality
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

- (NSInteger) relationshipCardinality
{
	return mRelationshipCardinality;
}

- (BOOL) hasRelationships
{
	return mHasRelationships;
}
@end
