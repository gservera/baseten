//
// BXDatabaseObjectModelMOMSerialization.mm
// BaseTen
//
// Copyright 2009-2010 Marko Karppinen & Co. LLC.
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

#import "BXDatabaseObjectModelMOMSerialization.h"
#import <CoreData/CoreData.h>
#import <tr1/unordered_map>
#import "BXDatabaseObjectModel.h"
#import "BXEnumerate.h"
#import "BXEntityDescription.h"
#import "BXAttributeDescription.h"
#import "BXRelationshipDescription.h"
#import "BXRelationshipDescriptionPrivate.h"
#import "BXLogger.h"
#import "BXForeignKey.h"
#import "BXHOM.h"
#import "BXCollectionFunctions.h"


using namespace BaseTen;


__strong static NSDictionary *gTypeMapping;
__strong static NSDictionary *gNameMapping;


@implementation BXDatabaseObjectModelMOMSerialization
+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		
		gTypeMapping = [[NSDictionary alloc] initWithObjectsAndKeys:
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"bit",
						ObjectValue <NSAttributeType> (NSBooleanAttributeType),		@"bool",
						ObjectValue <NSAttributeType> (NSBinaryDataAttributeType),	@"bytea",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"char",
						ObjectValue <NSAttributeType> (NSDateAttributeType),		@"date",
						ObjectValue <NSAttributeType> (NSFloatAttributeType),		@"float4",
						ObjectValue <NSAttributeType> (NSDoubleAttributeType),		@"float8",
						ObjectValue <NSAttributeType> (NSInteger16AttributeType),	@"int2",
						ObjectValue <NSAttributeType> (NSInteger32AttributeType),	@"int4",
						ObjectValue <NSAttributeType> (NSInteger64AttributeType),	@"int8",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"name",
						ObjectValue <NSAttributeType> (NSDecimalAttributeType),		@"numeric",
						ObjectValue <NSAttributeType> (NSInteger32AttributeType),	@"oid",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"text",
						ObjectValue <NSAttributeType> (NSDateAttributeType),		@"timestamp",
						ObjectValue <NSAttributeType> (NSDateAttributeType),		@"timestamptz",
						ObjectValue <NSAttributeType> (NSDateAttributeType),		@"time",
						ObjectValue <NSAttributeType> (NSDateAttributeType),		@"timetz",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"varbit",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"varchar",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"bpchar",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"uuid",
						nil];
		gNameMapping = [[NSDictionary alloc] initWithObjectsAndKeys:
						@"modelDescription", @"description",
						@"modelObjectID", @"objectID",
						nil];
	}
}


+ (NSString *) managedObjectClassName
{
	return @"NSManagedObject";
}


+ (NSString *) sanitizedName: (NSString *) dbName
{
	NSString* retval = [gNameMapping objectForKey: dbName];
	if (! retval)
		retval = dbName;
	return retval;
}


+ (void) sanitizeAttrName: (BXAttributeDescription *) attr target: (NSMutableArray *) array
{
	[array addObject: [self sanitizedName: [attr name]]];
}


struct fkey_fn_st {
	__strong NSMutableArray* ff_srcNames;
	__strong NSMutableArray* ff_dstNames;
};


static void FkeyFnCallback (NSString* srcName, NSString* dstName, void* ctxPtr)
{
	struct fkey_fn_st* ctx = (struct fkey_fn_st *) ctxPtr;
	[ctx->ff_srcNames addObject: srcName];
	[ctx->ff_dstNames addObject: dstName];
}


struct fkey_excl_st
{
	__strong NSMutableSet* fn_excludedAttributes;
	__strong BXEntityDescription* fn_entity;
};


static void FkeyExclusionCallback (NSString* srcName, NSString* dstName, void* ctxPtr)
{
	struct fkey_excl_st* ctx = (struct fkey_excl_st *) ctxPtr;
	BXAttributeDescription* attr = [[ctx->fn_entity attributesByName] objectForKey: srcName];
	ExpectV (attr);
	[ctx->fn_excludedAttributes addObject: attr];
}


static int FilterVisibleAttrs (id attr)
{
	int retval = 0;
	if (1 <= [attr attributeIndex])
		retval = 1;
	return retval;
}


static NSInteger CompareAttrIndices (id lhs, id rhs, void* ctx)
{
	NSComparisonResult retval = NSOrderedSame;
	NSInteger lIdx = [lhs attributeIndex];
	NSInteger rIdx = [rhs attributeIndex];
	if (lIdx < rIdx)
		retval = NSOrderedAscending;
	else if (lIdx > rIdx)
		retval = NSOrderedDescending;
	return retval;
}


+ (NSManagedObjectModel *) managedObjectModelFromDatabaseObjectModel: (BXDatabaseObjectModel *) objectModel 
															 options: (BXDatabaseObjectModelSerializationOptions) options
															   error: (NSError **) outError
{
	NSManagedObjectModel* retval = [[[NSManagedObjectModel alloc] init] autorelease];
	
	const BOOL exportFkeyRelationships    = options & kBXDatabaseObjectModelSerializationOptionRelationshipsUsingFkeyNames;
	const BOOL exportRelNameRelationships = options & kBXDatabaseObjectModelSerializationOptionRelationshipsUsingTargetRelationNames;
	const BOOL excludeFkeyAttrs           = options & kBXDatabaseObjectModelSerializationOptionExcludeForeignKeyAttributes;
	const BOOL relationshipsAsOptional    = options & kBXDatabaseObjectModelSerializationOptionCreateRelationshipsAsOptional;
	
	NSArray* bxEntities = [objectModel entities];
	NSMutableArray* entities = [NSMutableArray arrayWithCapacity: [bxEntities count]];
	NSMutableSet* entityNames = [NSMutableSet setWithCapacity: [bxEntities count]];
	NSMutableDictionary* entitiesBySchema = [NSMutableDictionary dictionary];
	NSMutableSet* excludedAttributes = [NSMutableSet set];

	// Create entity descriptions for all entities.
	BXEnumerate (bxEntity, e, [bxEntities objectEnumerator])
	{
		// Currently we just skip views.
		if (! [bxEntity isView])
		{
			NSEntityDescription* currentEntity = [[[NSEntityDescription alloc] init] autorelease];
			[currentEntity setName: [bxEntity name]];
			
			NSMutableArray* attrs = (id) [[bxEntity attributesByName] BX_ValueSelectFunction: &FilterVisibleAttrs];
			[attrs sortUsingFunction: &CompareAttrIndices context: NULL];
			NSMutableArray* sanitizedNames = [NSMutableArray arrayWithCapacity: [attrs count]];
			[[attrs BX_Visit: self] sanitizeAttrName: nil target: sanitizedNames];
			
			[currentEntity setUserInfo: [NSDictionary dictionaryWithObject: sanitizedNames forKey: @"Sorted Attribute Names"]];
			
			NSMutableArray* currentSchema = [entitiesBySchema objectForKey: [bxEntity schemaName]];
			if (! currentSchema)
			{
				currentSchema = [NSMutableArray array];
				[entitiesBySchema setObject: currentSchema forKey: [bxEntity schemaName]];
			}
			[currentSchema addObject: currentEntity];
			
			//FIXME: change this into an error.
			Expect (! [entityNames containsObject: [currentEntity name]]);
			[entityNames addObject: [currentEntity name]];
			
			[entities addObject: currentEntity];
			[currentEntity setManagedObjectClassName: [self managedObjectClassName]];
		}
	}
	
	[retval setEntities: entities];
	
	// Create configurations based on schema names.
	BXEnumerate (currentSchema, e, [entitiesBySchema keyEnumerator])
	{
		[retval setEntities: [entitiesBySchema objectForKey: currentSchema] 
		   forConfiguration: currentSchema];
	}
	
	// Create attributes and relationships.
	BXEnumerate (bxEntity, e, [bxEntities objectEnumerator])
	{
		NSEntityDescription* currentEntity = [[retval entitiesByName] objectForKey: [bxEntity name]];
		NSDictionary* attributesByName = [bxEntity attributesByName];

		[excludedAttributes removeAllObjects];
		struct fkey_excl_st fkeyContext = {excludedAttributes, bxEntity};

		NSDictionary* relationshipsByName = nil;
		if ([bxEntity hasCapability: kBXEntityCapabilityRelationships])
			relationshipsByName = [bxEntity relationshipsByName];
		
		NSMutableArray* properties = [NSMutableArray arrayWithCapacity:
									  [attributesByName count] + [relationshipsByName count]];
		
		BXEnumerate (bxRel, e, [relationshipsByName objectEnumerator])
		{
			BOOL usesRelNames = [bxRel usesRelationNames];
			if (((usesRelNames && exportRelNameRelationships) ||
				 (!usesRelNames && exportFkeyRelationships)) && 
				! [bxRel isDeprecated])
			{
				BXEntityDescription* bxDst = [(BXRelationshipDescription *) bxRel destinationEntity];
				if (! ([bxEntity isView] || [bxDst isView]))
				{
					NSRelationshipDescription* rel = [[[NSRelationshipDescription alloc] init] autorelease];
					[properties addObject: rel];
					
					NSEntityDescription* dst = [[retval entitiesByName] objectForKey: [bxDst name]];

					[rel setName: [self sanitizedName: [bxRel name]]];
					[rel setDestinationEntity: dst];
					if (! [bxRel isToMany])
						[rel setMaxCount: 1];
					if (relationshipsAsOptional || [bxRel isOptional])
						[rel setOptional: YES];
					else
					{
						[rel setMinCount: 1];
						[rel setOptional: NO];
					}

					if (![bxRel isToMany] && [bxRel isInverse])
					{
						id <BXForeignKey> fkey = [bxRel foreignKey];
						
						// Exclude foreign key fields from attributes. Core Data wouldn't update them anyway.
						if (excludeFkeyAttrs)
							[fkey iterateColumnNames: &FkeyExclusionCallback context: &fkeyContext];

						// Add fkey name and field names to relationship's userInfo.
						NSUInteger count = [fkey numberOfColumns];
						NSMutableArray* srcNames = [NSMutableArray arrayWithCapacity: count];
						NSMutableArray* dstNames = [NSMutableArray arrayWithCapacity: count];
						struct fkey_fn_st fkeyFNames = {srcNames, dstNames};
						[fkey iterateColumnNames: &FkeyFnCallback context: &fkeyFNames];
						NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
												  [fkey name], @"Foreign key",
												  srcNames, @"Foreign key source fields",
												  dstNames, @"Foreign key destination fields",
												  nil];
						[rel setUserInfo: userInfo];						
					}
				}
			}
		}
		
		BXEnumerate (bxAttr, e, [attributesByName objectEnumerator])
		{
			if (! ([bxAttr isExcluded] || [excludedAttributes containsObject: bxAttr]))
			{
				NSAttributeDescription* attr = [[[NSAttributeDescription alloc] init] autorelease];
				[properties addObject: attr];
				
				[attr setName: [self sanitizedName: [bxAttr name]]];
				[attr setOptional: [bxAttr isOptional]];
				
				NSAttributeType attributeType = NSUndefinedAttributeType;
				FindElement (gTypeMapping, [bxAttr databaseTypeName], &attributeType);
				[attr setAttributeType: attributeType];
				
				NSDictionary* userInfo = [NSDictionary dictionaryWithObject: [bxAttr databaseTypeName] forKey: @"Database type"];
				[attr setUserInfo: userInfo];
			}
		}		

		[currentEntity setProperties: properties];
	}
	
	// Set inverse relationships.
	BXEnumerate (bxEntity, e, [bxEntities objectEnumerator])
	{
		NSEntityDescription* entity = [[retval entitiesByName] objectForKey: [bxEntity name]];
		if (entity && [bxEntity hasCapability: kBXEntityCapabilityRelationships])
		{
			BXEnumerate (bxRel, e, [[bxEntity relationshipsByName] objectEnumerator])
			{
				NSRelationshipDescription* rel = [[entity relationshipsByName] objectForKey: [bxRel name]];
				if (rel && ! [rel inverseRelationship])
				{
					BXRelationshipDescription* bxDstRel = [(BXRelationshipDescription *) bxRel inverseRelationship];
					BXEntityDescription* bxDst = [bxDstRel entity];
					NSEntityDescription* dst = [[retval entitiesByName] objectForKey: [bxDst name]];
					NSString* inverseName = [[bxRel inverseRelationship] name];
					NSRelationshipDescription* inverse = [[dst relationshipsByName] objectForKey: inverseName];
					
					[rel setInverseRelationship: inverse];
					[inverse setInverseRelationship: rel];
				}
			}
		}
	}
	
	return retval;
}
@end
