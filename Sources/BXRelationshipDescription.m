//
// BXRelationshipDescription.m
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

#import "BXRelationshipDescription.h"
#import "BXRelationshipDescriptionPrivate.h"
#import "BXEntityDescriptionPrivate.h"
#import "BXDatabaseObject.h"
#import "BXForeignKey.h"
#import "BXDatabaseContext.h"
#import "BXDatabaseContextPrivate.h"
#import "BXSetRelationProxy.h"
#import "BXDatabaseObjectPrivate.h"
#import "BXLogger.h"
#import "BXHOM.h"
#import "BXPropertyDescriptionPrivate.h"
#import "BXProbes.h"
#import "BXAttributeDescriptionPrivate.h"
#import "BXEnumerate.h"


/**
 * \brief A description for one-to-many relationships and a superclass for others.
 *
 * Relationships between entities are defined with foreign keys in the database.
 * \note This class's documented methods are thread-safe. Creating objects, however, is not.
 * \note For this class to work in non-GC applications, the corresponding database context must be retained as well.
 * \ingroup descriptions
 */
@implementation BXRelationshipDescription
- (id) initWithName: (NSString *) name entity: (BXEntityDescription *) entity 
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

- (void) dealloc
{
	[mForeignKey release];
	[mInverseName release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"<%@ (%p) name: %@ entity: %@ destinationEntity: %@>",
		[self class], self, [self name], 
		(id) [[self entity] name] ?: [self entity], 
		(id) [[self destinationEntity] name] ?: [self destinationEntity]];
}

/**
 * \brief Destination entity for this relationship.
 */
- (BXEntityDescription *) destinationEntity
{
    return mDestinationEntity;
}

/**
 * \brief Inverse relationship for this relationship.
 */
- (BXRelationshipDescription *) inverseRelationship
{
	BXRelationshipDescription* retval = nil;
	if ([mDestinationEntity hasCapability: kBXEntityCapabilityRelationships])
		retval = [[mDestinationEntity relationshipsByName] objectForKey: mInverseName];
	return retval;
}

/**
 * \brief Delete rule for this relationship.
 */
- (NSDeleteRule) deleteRule
{
	//We only have a delete rule for the foreign key's source table.
	//If it isn't also the relationship's source table, we have no way of controlling deletion.
	return ([self isInverse] ? NSNullifyDeleteRule : [mForeignKey deleteRule]);
}

/**
 * \brief Whether this relationship is to-many.
 */
- (BOOL) isToMany
{
	return !mIsInverse;
}

- (BOOL) isEqual: (id) anObject
{
	BOOL retval = NO;
	//Foreign keys and destination entities needn't be compared, because relationship names are unique in their entities.
	if (anObject == self || ([super isEqual: anObject]))
		retval = YES;
    return retval;	
}

//FIXME: need we this?
#if 0
- (id) mutableCopyWithZone: (NSZone *) zone
{
	BXRelationshipDescription* retval = [super mutableCopyWithZone: zone];
	retval->mDestinationEntity = mDestinationEntity;
	retval->mForeignKey = [mForeignKey copy];
	retval->mInverseName = [mInverseName copy];
	retval->mDeleteRule = mDeleteRule;
	retval->mIsInverse = mIsInverse;
	
	return retval;
}
#endif

- (enum BXPropertyKind) propertyKind
{
	return kBXPropertyKindRelationship;
}

- (BOOL) isDeprecated
{
	return mIsDeprecated;
}
@end


@implementation BXRelationshipDescription (PrivateMethods)
- (id) initWithName: (NSString *) name 
			 entity: (BXEntityDescription *) entity 
  destinationEntity: (BXEntityDescription *) destinationEntity
{
	Expect (name);
	Expect (entity);
	Expect (destinationEntity);
	
	if ((self = [super initWithName: name entity: entity]))
	{
		mDestinationEntity = destinationEntity;
	}
	return self;
}


struct rel_attr_st
{
	__strong BXRelationshipDescription* ra_sender;
	__strong NSDictionary* ra_attrs;
};


static void
RemoveRelFromAttribute (NSString* srcKey, NSString* dstKey, void* context)
{
	struct rel_attr_st* ctx = (struct rel_attr_st *) context;
	BXRelationshipDescription* self = ctx->ra_sender;
	NSDictionary* attributes = ctx->ra_attrs;
	
	BXAttributeDescription* attr = [attributes objectForKey: srcKey];
	ExpectV (attr);
	[attr removeDependentRelationship: self];
}


static void
AddRelToAttribute (NSString* srcKey, NSString* dstKey, void* context)
{
	struct rel_attr_st* ctx = (struct rel_attr_st *) context;
	BXRelationshipDescription* self = ctx->ra_sender;
	NSDictionary* attributes = ctx->ra_attrs;
	
	BXAttributeDescription* attr = [attributes objectForKey: srcKey];
	ExpectV (attr);
	[attr addDependentRelationship: self];
}


- (void) removeAttributeDependency
{
	if ([self isInverse] && ![self isToMany])
	{
		struct rel_attr_st ctx = {self, [[self entity] attributesByName]};
		[[self foreignKey] iterateColumnNames: &RemoveRelFromAttribute context: &ctx];
	}
}


- (void) makeAttributeDependency
{
	if ([self isInverse] && ![self isToMany])
	{
		struct rel_attr_st ctx = {self, [[self entity] attributesByName]};
		[[self foreignKey] iterateColumnNames: &AddRelToAttribute context: &ctx];
	}
}


- (void) setForeignKey: (id <BXForeignKey>) aKey
{
	if (mForeignKey != aKey)
	{
		[mForeignKey release];
		mForeignKey = [aKey retain];		
	}
}

- (BOOL) usesRelationNames
{
	return mUsesRelationNames;
}

- (void) setUsesRelationNames: (BOOL) aBool
{
	mUsesRelationNames = aBool;
}

- (void) setIsInverse: (BOOL) aBool
{
	mIsInverse = aBool;
}

/** \brief Whether this relationship is inverse. */
- (BOOL) isInverse
{
	return mIsInverse;
}

- (void) setDeprecated: (BOOL) aBool
{
	mIsDeprecated = aBool;
}

- (void) setInverseName: (NSString *) aString
{
	if (mInverseName != aString)
	{
		[mInverseName release];
		mInverseName = [aString retain];
	}
}

- (NSPredicate *) predicateForObject: (BXDatabaseObject *) databaseObject
{
	BXRelationshipDescription* inverse = [self inverseRelationship];
	NSComparisonPredicateModifier modifier = NSDirectPredicateModifier;
	if ([inverse isToMany])
		modifier = NSAnyPredicateModifier;
	
	NSExpression* lhs = [NSExpression expressionForKeyPath: [inverse name]];
	NSExpression* rhs = [NSExpression expressionForConstantValue: databaseObject];
	NSPredicate* predicate = [NSComparisonPredicate predicateWithLeftExpression: lhs
																rightExpression: rhs
																	   modifier: modifier 
																		   type: NSEqualToPredicateOperatorType 
																		options: 0];
	return predicate;
}

//Subclassing helpers
- (NSPredicate *) predicateForRemoving: (id) target 
						databaseObject: (BXDatabaseObject *) databaseObject
{
	NSPredicate* retval = nil;
	
	//Compare collection to cached values.
	NSSet* oldObjects = [databaseObject primitiveValueForKey: [self name]];	
	
	NSMutableSet* removedObjects = [[oldObjects mutableCopy] autorelease];
	[removedObjects minusSet: target];
	
	if (0 < [removedObjects count])
	{
		NSExpression* lhs = [NSExpression expressionForConstantValue: removedObjects];
		NSExpression* rhs = [NSExpression expressionForEvaluatedObject];
		retval = [NSComparisonPredicate predicateWithLeftExpression: lhs rightExpression: rhs
														   modifier: NSAnyPredicateModifier 
															   type: NSEqualToPredicateOperatorType 
															options: 0];
	}
	return retval;
}

- (NSPredicate *) predicateForAdding: (id) target 
					  databaseObject: (BXDatabaseObject *) databaseObject
{
	NSPredicate* retval = nil;
	
	//Compare collection to cached values.
	NSSet* oldObjects = [databaseObject primitiveValueForKey: [self name]];	
	NSMutableSet* addedObjects = [[target mutableCopy] autorelease];
	[addedObjects minusSet: oldObjects];
	
	if (0 < [addedObjects count])
	{
		NSExpression* lhs = [NSExpression expressionForConstantValue: addedObjects];
		NSExpression* rhs = [NSExpression expressionForEvaluatedObject];
		retval = [NSComparisonPredicate predicateWithLeftExpression: lhs rightExpression: rhs
														   modifier: NSAnyPredicateModifier 
															   type: NSEqualToPredicateOperatorType 
															options: 0];
	}
	return retval;
}

- (Class) fetchedClass
{
	return [BXSetRelationProxy class];
}

- (id) toOneTargetFor: (BXDatabaseObject *) databaseObject registeredOnly: (BOOL) registeredOnly 
			fireFault: (BOOL) fireFault error: (NSError **) error
{
	Expect ([self isInverse]);
	Expect (! [self isToMany]);
	Expect (registeredOnly || error);

	BXDatabaseObject* retval = nil;
	BXEntityDescription* entity = [self destinationEntity];
	BXDatabaseObjectID* objectID = BXFkeyDstObjectID (mForeignKey, entity, databaseObject, fireFault);
	if (objectID)
	{
		BXDatabaseContext* ctx = [databaseObject databaseContext];
		if (registeredOnly)
			retval = [ctx registeredObjectWithID: objectID];
		else
			retval = [ctx objectWithID: objectID error: error];	
	}
	return retval;
}
			
- (id) registeredTargetFor: (BXDatabaseObject *) databaseObject fireFault: (BOOL) fireFault
{
	id retval = nil;
	if (databaseObject)
		retval = [self toOneTargetFor: databaseObject registeredOnly: YES fireFault: fireFault error: NULL];
	return retval;
}

- (id) targetForObject: (BXDatabaseObject *) databaseObject error: (NSError **) error
{
	Expect (error);
	Expect (databaseObject);
    BXAssertValueReturn ([[self entity] isEqual: [databaseObject entity]], nil, 
						 @"Expected object's entity to match. Self: %@ aDatabaseObject: %@", self, databaseObject);
	
	if (mIsDeprecated) 
	{
		BXDeprecationLogSpecific (@"The relationship name '%@' in %@.%@ has been deprecated (inverse relationship is '%@').",
								  mName, [mEntity schemaName], [mEntity name], [[self inverseRelationship] name]);
	}
	
	id retval = nil;
	//If we can determine an object ID, fetch the target object from the context's cache.
    if (! [self isToMany] && [self isInverse])
		retval = [self toOneTargetFor: databaseObject registeredOnly: NO fireFault: YES error: error];
	else
	{
		BXEntityDescription* entity = [self destinationEntity];
		NSPredicate* predicate = [self predicateForObject: databaseObject];
		Class fetchedClass = [self fetchedClass];
		id res = [[databaseObject databaseContext] executeFetchForEntity: entity
														   withPredicate: predicate 
														 returningFaults: NO
														 excludingFields: nil
														   returnedClass: fetchedClass
																   error: error];
		if (fetchedClass)
			[res fetchedForRelationship: self owner: databaseObject key: [self name]];
		
		if ([self isToMany])
			retval = res;
		else
			retval = [res BX_Any];
	}
	
	if (! retval)
		retval = [NSNull null];
	
	return retval;
}

- (BOOL) setTarget: (id) target
		 forObject: (BXDatabaseObject *) databaseObject
			 error: (NSError **) error
{
	ExpectR (error, NO);
	ExpectR (databaseObject, NO);
	ExpectR ([[self entity] isEqual: [databaseObject entity]], NO);
	
	if (mIsDeprecated) 
	{
		BXDeprecationLogSpecific (@"The relationship name %@ in %@.%@ has been deprecated.",
								  mName, [mEntity schemaName], [mEntity name]);
	}
	
	BOOL retval = NO;
	BXRelationshipDescription* inverse = [self inverseRelationship];
	NSString* inverseName = [inverse name];
	
    //We always want to modify the foreign key's (or corresponding view's) entity, hence the branch here.
	//Also with one-to-many relationships the false branch is for modifying a collection of objects.
    if (mIsInverse)
    {		
		NSDictionary* values = BXFkeySrcDictionary (mForeignKey, [self entity], target);
		
		BXDatabaseObject* oldTarget = nil;
		if (inverseName)
		{
			oldTarget = [self registeredTargetFor: databaseObject fireFault: NO];
			[oldTarget willChangeValueForKey: inverseName];
			[target willChangeValueForKey: inverseName];
		}
		
    	[[databaseObject databaseContext] executeUpdateObject: databaseObject
													   entity: [self entity]
													predicate: nil
											   withDictionary: values
														error: error];
    	if (! *error)
    		[databaseObject setCachedValue: target forKey: [self name]];

		if (inverseName)
		{
			[oldTarget didChangeValueForKey: inverseName];
			[target didChangeValueForKey: inverseName];
		}

		if (*error)
			goto bail;
    }
    else
    {
    	//First remove old objects from the relationship, then add new ones.
    	//FIXME: this could be configurable by the user unless we want to look for non-empty or maximum size constraints, which are likely CHECK clauses.
    	//FIXME: these should be inside a transaction. Use the undo manager?
		
		BXDatabaseObject* oldTarget = nil;
		if (! [self isToMany] && inverseName)
		{
			oldTarget = [databaseObject cachedValueForKey: [self name]];
			[oldTarget willChangeValueForKey: inverseName];
			[target willChangeValueForKey: inverseName];
		}
		
		NSPredicate* predicate = nil;
    	if ((predicate = [self predicateForRemoving: target databaseObject: databaseObject]))
    	{
			NSDictionary* values = BXFkeySrcDictionary (mForeignKey, [self destinationEntity], nil);
    		[[databaseObject databaseContext] executeUpdateObject: nil
    														entity: [self destinationEntity]
    													 predicate: predicate 
    												withDictionary: values
    														 error: error];
			
			if (*error)
				goto bail;
    	}
		
		if ((predicate = [self predicateForAdding: target databaseObject: databaseObject]))
		{
			NSDictionary* values = BXFkeySrcDictionary (mForeignKey, [self destinationEntity], databaseObject);
			[[databaseObject databaseContext] executeUpdateObject: nil
														   entity: [self destinationEntity]
														predicate: predicate 
												   withDictionary: values
															error: error];
			
			if (*error)
				goto bail;
		}
				
		//Don't set if we are updating a collection because if the object has the
		//value, it will be self-updating one.
		if (! [self isToMany] && inverseName)
		{
			[oldTarget didChangeValueForKey: inverseName];
			[target didChangeValueForKey: inverseName];
		}
	}
	
	retval = YES;
bail:
	return retval;
}

- (id <BXForeignKey>) foreignKey
{
	return mForeignKey;
}

- (void) iterateForeignKey: (void (*)(NSString*, NSString*, void*)) callback context: (void *) ctx
{
	if ([self isInverse])
		[[self foreignKey] iterateColumnNames: callback context: ctx];
	else
		[[self foreignKey] iterateReversedColumnNames: callback context: ctx];
}
@end


@implementation BXRelationshipDescription (BXPGRelationAliasMapper)
- (id) BXPGVisitRelationship: (id <BXPGRelationshipVisitor>) visitor fromItem: (BXPGRelationshipFromItem *) fromItem
{
	return [visitor visitSimpleRelationship: fromItem];
}
@end
