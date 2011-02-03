//
// BXAttributeDescription.m
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

#import "BXPropertyDescription.h"
#import "BXAttributeDescription.h"
#import "BXAttributeDescriptionPrivate.h"
#import "BXEntityDescription.h"
#import "BXRelationshipDescription.h"
#import "BXPropertyDescriptionPrivate.h"
#import "BXLogger.h"
#import "BXSetFunctions.h"


@class BXRelationshipDescription;


/**
 * \brief An attribute description contains information about a column in a specific entity.
 * \note This class's documented methods are thread-safe. Creating objects, however, is not.
 * \note For this class to work in non-GC applications, the corresponding database context must be retained as well.
 * \ingroup descriptions
 */
@implementation BXAttributeDescription
- (void) dealloc
{
	[mRelationshipsUsing release];
	[mDatabaseTypeName release];
	[super dealloc];
}

#if 0
- (id) initWithCoder: (NSCoder *) decoder
{
	if ((self = [super initWithCoder: decoder]))
	{
		[self setPrimaryKey: [decoder decodeBoolForKey: @"isPrimaryKey"]];
		//FIXME: excludedByDefault
		[self setExcluded: [decoder decodeBoolForKey: @"isExcluded"]];
		mRelationshipsUsing = PGTSSetCreateMutableStrongRetainingForNSRD ();
	}
	return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
	[coder encodeBool: [self isPrimaryKey] forKey: @"isPrimaryKey"];
	//FIXME: excludedByDefault
	[coder encodeBool: [self isExcluded] forKey: @"isExcluded"];
	[super encodeWithCoder: coder];
}
#endif

/** \brief Whether the attribute is part of the primary key of its entity. */
- (BOOL) isPrimaryKey
{
	return (mFlags & kBXPropertyPrimaryKey ? YES : NO);
}

/** 
 * \brief Whether the attribute will be excluded from fetches and queried only when needed. 
 * \see BXDatabaseContext::executeFetchForEntity:withPredicate:excludingFields:error:
 */
- (BOOL) isExcluded
{
	return (mFlags & kBXPropertyExcluded ? YES : NO);
}

- (BOOL) isInherited
{
	return (mFlags & kBXPropertyInherited ? YES : NO);
}

/** \brief Name of the attribute's database type. */
- (NSString *) databaseTypeName
{
	return mDatabaseTypeName;
}

/** \brief Class of fetched objects. */
- (Class) attributeValueClass
{
	return mAttributeClass;
}

/** \brief Class name of fetched values. */
- (NSString *) attributeValueClassName
{
	return NSStringFromClass (mAttributeClass);
}

- (NSInteger) attributeIndex
{
	return mAttributeIndex;
}

- (enum BXPropertyKind) propertyKind
{
	return kBXPropertyKindAttribute;
}

/** \brief Whether this attribute is an array or not. */
- (BOOL) isArray
{
	return (kBXPropertyIsArray & mFlags ? YES : NO);
}
@end


@implementation BXAttributeDescription (PrivateMethods)
/** 
 * \internal
 * \name Creating an attribute description
 */
//@{
- (id) initWithName: (NSString *) name entity: (BXEntityDescription *) entity
{
	if ((self = [super initWithName: name entity: entity]))
	{
		mRelationshipsUsing = BXSetCreateMutableStrongRetainingForNSRD ();
	}
	return self;
}

/**
 * \internal
 * \brief Create an attribute description.
 * \param       aName       Name of the attribute
 * \param       anEntity    The entity which contains the attribute.
 * \return                  The attribute description.
 */
+ (id) attributeWithName: (NSString *) aName entity: (BXEntityDescription *) anEntity
{
    return [[[self alloc] initWithName: aName entity: anEntity] autorelease];
}
//@}

- (void) setArray: (BOOL) isArray
{
	if (isArray)
		mFlags |= kBXPropertyIsArray;
	else
		mFlags &= ~kBXPropertyIsArray;
}

- (void) setPrimaryKey: (BOOL) aBool
{
	[mEntity willChangeValueForKey: @"primaryKeyFields"];
	if (aBool)
	{
		mFlags |= kBXPropertyPrimaryKey;
		mFlags &= ~kBXPropertyExcluded;
	}
	else
	{
		mFlags &= ~kBXPropertyPrimaryKey;
	}
	[mEntity didChangeValueForKey: @"primaryKeyFields"];
}

- (void) setExcluded: (BOOL) aBool
{
	if (![self isPrimaryKey])
	{
		if (aBool)
			mFlags |= kBXPropertyExcluded;
		else
			mFlags &= ~kBXPropertyExcluded;
	}
}

- (void) setExcludedByDefault: (BOOL) aBool
{
	if (![self isPrimaryKey])
	{
		if (aBool)
			mFlags |= kBXPropertyExcludedByDefault;
		else
			mFlags &= ~kBXPropertyExcludedByDefault;
	}
}

- (void) setInherited: (BOOL) aBool
{
	if (aBool)
		mFlags |= kBXPropertyInherited;
	else
		mFlags &= ~kBXPropertyInherited;
}

- (void) resetAttributeExclusion
{
	if (kBXPropertyExcludedByDefault & mFlags)
		mFlags |= kBXPropertyExcluded;
	else
		mFlags &= ~kBXPropertyExcluded;
}

- (void) setAttributeIndex: (NSInteger) idx
{
	mAttributeIndex = idx;
}

- (void) setAttributeValueClass: (Class) aClass
{
	mAttributeClass = aClass;
}

- (void) setDatabaseTypeName: (NSString *) typeName
{
	if (mDatabaseTypeName != typeName)
	{
		[mDatabaseTypeName release];
		mDatabaseTypeName = [typeName retain];
	}
}

- (void) addDependentRelationship: (BXRelationshipDescription *) rel
{
	ExpectV (mRelationshipsUsing);
	@synchronized (mRelationshipsUsing)
	{
		ExpectV ([rel destinationEntity]);
		if ([[rel entity] isEqual: [self entity]])
		{
			[mRelationshipsUsing addObject: rel];
		}
		else
		{
			BXLogError (@"Tried to add a relationship doesn't correspond to current attribute. Attribute: %@ relationship: %@", self, rel);
		}
	}	
}

- (void) removeDependentRelationship: (BXRelationshipDescription *) rel
{
	@synchronized (mRelationshipsUsing)
	{
		[mRelationshipsUsing removeObject: rel];
	}
}

- (NSSet *) dependentRelationships
{
	id retval = nil;
	@synchronized (mRelationshipsUsing)
	{
		retval = [[mRelationshipsUsing copy] autorelease];
	}
	return retval;
}
@end



@implementation BXAttributeDescription (BXExpressionValue)
- (enum BXExpressionValueType) getBXExpressionValue: (id *) outValue usingContext: (NSMutableDictionary *) ctx;
{
	ExpectR (outValue, kBXExpressionValueTypeUndefined);
	
	BXEntityDescription* myEntity = [self entity];
	BXEntityDescription* primaryRelation = [ctx objectForKey: kBXEntityDescriptionKey];
	ExpectR (primaryRelation, kBXExpressionValueTypeUndefined);
	BXAssertValueReturn ([myEntity isEqual: primaryRelation], kBXExpressionValueTypeUndefined, 
						 @"BXAttributeDescription as expression value is required to be one of the primary relation's attributes.");
	NSString* key = [self name];
	*outValue = [NSExpression expressionForKeyPath: key];
	return kBXExpressionValueTypeEvaluated;
}
@end
