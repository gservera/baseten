//
// BXSubqueryExpression.m
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

#import "BXSubqueryExpression.h"


@implementation BXSubqueryExpression
- (id) initWithSubquery: (NSExpression *) expression 
  usingIteratorVariable: (NSString *) variable 
			  predicate: (NSPredicate *) predicate
{
	if ((self = [super init]))
	{
		mCollection = [expression copy];
		mVariable = [NSExpression expressionForVariable: variable];
		mPredicate = [predicate copy];
	}
	return self;
}

+ (id) expressionForSubquery: (NSExpression *) expression 
	   usingIteratorVariable: (NSString *) variable 
				   predicate: (NSPredicate *) predicate
{
	id retval = [[[self alloc] initWithSubquery: expression usingIteratorVariable: variable predicate: predicate] autorelease];
	return retval;
}

- (void) dealloc
{
	[mCollection release];
	[mVariable release];
	[mPredicate release];
	[super dealloc];
}

- (NSExpression *) collection
{
	return mCollection;
}

- (NSExpression *) variableExpression
{
	return mVariable;
}

- (NSString *) variable
{
	return [mVariable variable];
}

- (NSPredicate *) predicate
{
	return mPredicate;
}

- (id) expressionValueWithObject: (id) object context: (NSMutableDictionary *) ctx
{
	NSString* variableName = [self variable];
	id oldValue = [ctx objectForKey: variableName];
	id collection = [mCollection expressionValueWithObject: object context: ctx];
	NSMutableArray* retval = [NSMutableArray arrayWithCapacity: [collection count]];
		
	BXEnumerate (currentObject, e, [collection objectEnumerator])
	{
		[ctx setObject: currentObject forKey: variableName];
		if ([mPredicate BXEvaluateWithObject: currentObject substitutionVariables: ctx])
			[retval addObject: currentObject];
	}
	
	[ctx setObject: oldValue forKey: variableName];
	return retval;
}
@end
