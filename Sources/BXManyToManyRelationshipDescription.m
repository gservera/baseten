//
// BXManyToManyRelationshipDescription.m
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


#import "BXManyToManyRelationshipDescription.h"
#import "BXRelationshipDescriptionPrivate.h"
#import "BXDatabaseObject.h"
#import "BXDatabaseContextPrivate.h"
#import "BXSetHelperTableRelationProxy.h"
#import "BXForeignKey.h"
#import "BXLogger.h"
#import "BXDatabaseObjectPrivate.h"
#import "BXEnumerate.h"


@implementation BXManyToManyRelationshipDescription
- (void) dealloc
{
	[mDstForeignKey release];
	[mHelperEntity release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"<%@ (%p) name: %@ entity: %@ destinationEntity: %@ helperEntity: %@>",
		[self class], self, [self name], [self entity], [self destinationEntity], mHelperEntity];
}

- (id <BXForeignKey>) dstForeignKey
{
	return mDstForeignKey;
}

- (void) setDstForeignKey: (id <BXForeignKey>) aKey
{
	if (mDstForeignKey != aKey)
	{
		[mDstForeignKey release];
		mDstForeignKey = [aKey retain];
	}
}

- (BXEntityDescription *) helperEntity
{
	return mHelperEntity;
}

- (void) setHelperEntity: (BXEntityDescription *) anEntity
{
	if (mHelperEntity != anEntity)
	{
		[mHelperEntity release];
		mHelperEntity = [anEntity retain];
	}
}

- (NSDeleteRule) deleteRule
{
	//Many-to-manys have always this delete rule, since our implementation 
	//modifies the helper table.
	return NSNullifyDeleteRule;
}

- (Class) fetchedClass
{
	return [BXSetHelperTableRelationProxy class];
}

struct PredicateContext
{
	BXDatabaseObject* pc_object;
	NSMutableArray* pc_parts;
};


static void
AddToFilterCompoundPredicate (NSString* helperKey, NSString* entityKey, void* context)
{
	struct PredicateContext* ctx = (struct PredicateContext *) context;
	ExpectCV (kBXDatabaseObjectUnknownKey < [ctx->pc_object keyType: entityKey]);
	
	NSString* predicateFormat = [NSString stringWithFormat: @"$%@.%%K == %%K", kBXOwnerObjectVariableName];
	NSPredicate* predicate = [NSPredicate predicateWithFormat: predicateFormat, entityKey, helperKey];
	[ctx->pc_parts addObject: predicate];
}


static void
AddToCompoundPredicate (NSString* helperKey, NSString* entityKey, void* context)
{
	struct PredicateContext* ctx = (struct PredicateContext *) context;
	id value = [ctx->pc_object primitiveValueForKey: entityKey];
	NSExpression* lhs = [NSExpression expressionForKeyPath: helperKey];
	NSExpression* rhs = [NSExpression expressionForConstantValue: value];
	NSPredicate* predicate = [NSComparisonPredicate predicateWithLeftExpression: lhs
																rightExpression: rhs
																	   modifier: NSDirectPredicateModifier
																		   type: NSEqualToPredicateOperatorType
																		options: 0];
	[ctx->pc_parts addObject: predicate];
}

- (NSPredicate *) predicateForAnyObject: (NSSet *) objects
{
	NSPredicate* retval = nil;
	id <BXForeignKey> fkey = [self foreignKey];	

	//FIXME: perhaps handle the case where 1 == [[fkey fieldNames] count] with an IN predicate?
	
	{
		NSMutableArray* objectParts = [NSMutableArray arrayWithCapacity: [objects count]];
		NSMutableArray* fkeyParts = [NSMutableArray arrayWithCapacity: [fkey numberOfColumns]];
		struct PredicateContext ctx = {nil, fkeyParts};
		BXEnumerate (currentObject, e, [objects objectEnumerator])
		{
			ctx.pc_object = currentObject;  
			[self iterateForeignKey: &AddToCompoundPredicate context: &ctx];
			NSPredicate* predicate = [NSCompoundPredicate andPredicateWithSubpredicates: ctx.pc_parts];
			[objectParts addObject: predicate];
			[ctx.pc_parts removeAllObjects];
		}
		retval = [NSCompoundPredicate orPredicateWithSubpredicates: objectParts];
	}
	return retval;
}

//When sending queries, a predicate that has fkey values is needed.
//Set proxies, on the other hand, benefit from predicates that have a variable reference to the owner object.
//This way changes in primary key values don't matter.
- (NSPredicate *) predicateFor: (BXDatabaseObject *) object useWithContainerProxy: (BOOL) useWithContainerProxy
{
	Expect (object);
	Expect ([[object entity] isEqual: [self entity]]);
	
	id <BXForeignKey> fkey = [self foreignKey];
	NSMutableArray* fkeyParts = [NSMutableArray arrayWithCapacity: [fkey numberOfColumns]];
	struct PredicateContext ctx = {object, fkeyParts};
	
	if (useWithContainerProxy)
		[fkey iterateColumnNames: &AddToFilterCompoundPredicate context: &ctx];
	else
		[fkey iterateColumnNames: &AddToCompoundPredicate context: &ctx];
		
	NSPredicate* predicate = [NSCompoundPredicate andPredicateWithSubpredicates: ctx.pc_parts];
	return predicate;	
}

- (NSPredicate *) objectPredicateFor: (BXDatabaseObject *) object
{
	return [self predicateFor: object useWithContainerProxy: NO];
}

- (NSPredicate *) filterPredicateFor: (BXDatabaseObject *) object
{
	return [self predicateFor: object useWithContainerProxy: YES];
}

- (BOOL) setTarget: (id) target
		 forObject: (BXDatabaseObject *) databaseObject
			 error: (NSError **) error
{
	ExpectR (error, NO);
	ExpectR (databaseObject, NO);
	ExpectR ([[self entity] isEqual: [databaseObject entity]], NO);
	
	if (mIsDeprecated) BXDeprecationWarning ();
	
	BOOL retval = NO;
	NSString* name = [self name];

	//Compare collection to cached values.
	NSSet* oldObjects = [databaseObject primitiveValueForKey: name];
	NSMutableSet* removedObjects = [[oldObjects mutableCopy] autorelease];
	[removedObjects minusSet: target];
	NSMutableSet* addedObjects = [[target mutableCopy] autorelease];
	[addedObjects minusSet: oldObjects];
	
	//First remove old objects from the relationship, then add new ones.
	//FIXME: this could be configurable by the user unless we want to look for non-empty or maximum size constraints, which are likely CHECK clauses.
	//FIXME: these should be inside a transaction. Use the undo manager?
	BXDatabaseContext* context = [databaseObject databaseContext];
	
	//Remove all objects from current object's set.
	if (0 < [removedObjects count])
	{
		NSPredicate* removedPredicate = [(id) [self inverseRelationship] predicateForAnyObject: removedObjects];
		NSPredicate* objectPredicate = [self objectPredicateFor: databaseObject];
		NSPredicate* predicate = [NSCompoundPredicate andPredicateWithSubpredicates: 
								  [NSArray arrayWithObjects: removedPredicate, objectPredicate, nil]];
		
		[context executeDeleteFromEntity: mHelperEntity
						   withPredicate: predicate 
								   error: error];
		if (*error)
			goto bail;
	}
	
	//Add objects to current object's set.
	//First get values for helper entity from source foreign key and then add values from each destination object.
	//Here, src for the foreign key is always mHelper.
	NSDictionary* srcHelperValues = BXFkeySrcDictionary ([self foreignKey], mHelperEntity, databaseObject);
	BXEnumerate (currentObject, e, [addedObjects objectEnumerator])
	{
		NSMutableDictionary* values = BXFkeySrcDictionary ([self dstForeignKey], mHelperEntity,  currentObject);
		[values addEntriesFromDictionary: srcHelperValues];
		[context createObjectForEntity: mHelperEntity
					   withFieldValues: values 
								 error: error];
		
		if (nil != *error)
			goto bail;
	}
	
		//Don't set since if the object has the collection cached, it will be self-updating one.
	
	retval = YES;
bail:
	return retval;
}

- (void) iterateForeignKey: (void (*)(NSString*, NSString*, void*)) callback context: (void *) ctx
{
	[[self foreignKey] iterateColumnNames: callback context: ctx];
}

- (void) iterateDstForeignKey: (void (*)(NSString*, NSString*, void*)) callback context: (void *) ctx
{
	[[self dstForeignKey] iterateColumnNames: callback context: ctx];
}

- (void) removeAttributeDependency
{
}


- (void) makeAttributeDependency
{
}
@end


@implementation BXManyToManyRelationshipDescription (BXPGRelationAliasMapper)
- (id) BXPGVisitRelationship: (id <BXPGRelationshipVisitor>) visitor fromItem: (BXPGHelperTableRelationshipFromItem *) fromItem
{
	return [visitor visitManyToManyRelationship: fromItem];
}
@end
