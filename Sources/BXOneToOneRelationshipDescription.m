//
// BXOneToOneRelationshipDescription.m
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


#import "BXOneToOneRelationshipDescription.h"
#import "BXDatabaseObject.h"
#import "BXForeignKey.h"
#import "BXRelationshipDescriptionPrivate.h"
#import "BXLogger.h"


@implementation BXOneToOneRelationshipDescription

- (BOOL) isToMany
{
	return NO;
}

- (Class) fetchedClass
{
	return Nil;
}

- (NSPredicate *) predicateForRemoving: (id) target 
						databaseObject: (BXDatabaseObject *) databaseObject
{
	NSPredicate* retval = nil;	
	BXDatabaseObject* oldObject = [databaseObject primitiveValueForKey: [self name]];
	if (oldObject)
	{
		NSExpression* lhs = [NSExpression expressionForConstantValue: oldObject];
		NSExpression* rhs = [NSExpression expressionForEvaluatedObject];
		retval = [NSComparisonPredicate predicateWithLeftExpression: lhs rightExpression: rhs
														   modifier: NSDirectPredicateModifier 
															   type: NSEqualToPredicateOperatorType 
															options: 0];
	}
	return retval;
}

- (NSPredicate *) predicateForAdding: (id) target 
					  databaseObject: (BXDatabaseObject *) databaseObject
{
	
	NSPredicate* retval = nil;
	if (target)
	{
		NSExpression* lhs = [NSExpression expressionForConstantValue: target];
		NSExpression* rhs = [NSExpression expressionForEvaluatedObject];
		retval = [NSComparisonPredicate predicateWithLeftExpression: lhs rightExpression: rhs
														   modifier: NSDirectPredicateModifier 
															   type: NSEqualToPredicateOperatorType 
															options: 0];
	}
	return retval;
}

- (NSPredicate *) predicateForTarget: (BXDatabaseObject *) target
{
	BXDatabaseObjectID* objectID = [target objectID];
	NSPredicate* retval = [objectID predicate];
	return retval;
}
@end
