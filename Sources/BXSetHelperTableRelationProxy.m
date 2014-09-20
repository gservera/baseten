//
// BXSetHelperTableRelationProxy.m
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

#import "BXSetHelperTableRelationProxy.h"
#import "BXDatabaseObjectID.h"
#import "BXDatabaseObjectIDPrivate.h"
#import "BXDatabaseContext.h"
#import "BXRelationshipDescriptionPrivate.h"
#import "BXManyToManyRelationshipDescription.h"
#import "BXForeignKey.h"
#import "BXEntityDescription.h"
#import "BXEnumerate.h"
#import "NSArray+BaseTenAdditions.h"


/**
 * \internal
 * \brief An NSMutableSet-style self-updating container proxy for many-to-many relationships.
 * \ingroup auto_containers
 */
//FIXME: this needs to be changed to use set mutation -style KVO notifications.
@implementation BXSetHelperTableRelationProxy

- (id) BXInitWithArray: (NSMutableArray *) anArray NS_RETURNS_RETAINED {
    return [super BXInitWithArray:anArray];
}

- (void) fetchedForEntity: (BXEntityDescription *) entity predicate: (NSPredicate *) predicate
{
}

- (void) fetchedForRelationship: (BXRelationshipDescription *) rel
						  owner: (BXDatabaseObject *) databaseObject
							key: (NSString *) key
{
	BXManyToManyRelationshipDescription* relationship = (id) rel;
	BXEntityDescription* entity = [relationship helperEntity];
	[self setEntity: entity];
	[self setRelationship: relationship];
	[self setOwner: databaseObject];
	[self setKey: key];
	[self setFilterPredicate: [relationship filterPredicateFor: databaseObject]];
}


struct set_pkf_st 
{
	__strong id s_object;
	__strong NSMutableDictionary* s_pkf_dict;
};


static void
SetPkeyFValues (NSString* helperFName, NSString* fName, void* ctx)
{
	struct set_pkf_st* sps = (struct set_pkf_st *) ctx;
	[sps->s_pkf_dict setObject: [sps->s_object primitiveValueForKey: helperFName] forKey: fName];
}


- (NSArray *) objectIDsFromHelperObjectIDs: (NSArray *) ids others: (NSMutableArray *) others
{
	
    //Iterate two times if ids that don't pass the filter should be added to otherObjectIDs
    int count = 1;
    if (others)
        count = 2;
	
	NSArray* faults = [mContext faultsWithIDs: ids];
	NSMutableArray* otherObjects = [NSMutableArray arrayWithCapacity: [faults count]];
	NSMutableDictionary* ctx = [self substitutionVariables];
	NSArray* filteredObjects = [faults BXFilteredArrayUsingPredicate: mFilterPredicate 
															  others: otherObjects
											   substitutionVariables: ctx];
	NSMutableArray* retval = [NSMutableArray arrayWithCapacity: [filteredObjects count]];
	
	id filtered [2] = {filteredObjects, otherObjects};
	id target [2] = {retval, others};
	id <BXForeignKey> dstFkey = [(BXManyToManyRelationshipDescription *) mRelationship dstForeignKey];
	NSMutableDictionary* pkeyFValues = [NSMutableDictionary dictionaryWithCapacity: [dstFkey numberOfColumns]];

	for (int i = 0; i < count; i++)
	{
		NSUInteger count = [filtered [i] count];
		if (0 < count)
		{
			BXEnumerate (currentObject, e, [filtered [i] objectEnumerator])
			{
				[pkeyFValues removeAllObjects];
				struct set_pkf_st ctx = {currentObject, pkeyFValues};
				[dstFkey iterateColumnNames: &SetPkeyFValues context: &ctx];
				BXDatabaseObjectID* objectID = [BXDatabaseObjectID IDWithEntity: [mRelationship destinationEntity] 
															   primaryKeyFields: pkeyFValues];
				[target [i] addObject: objectID];				
			}
		}
	}
	return retval;
}

- (void) addedObjectsWithIDs: (NSArray *) ids
{
    NSArray* objectIDs = [self objectIDsFromHelperObjectIDs: ids others: nil];
    if (0 < [objectIDs count])
	{
		//Post notifications since modifying a self-updating collection won't cause
		//value cache to be changed.
		NSString* key = [self key];
		ExpectL (mOwner && key);

		[mOwner willChangeValueForKey: key];
        [self handleAddedObjects: [mContext faultsWithIDs: objectIDs]];
		[mOwner didChangeValueForKey: key];
	}
}

- (void) removedObjectsWithIDs: (NSArray *) ids
{
    NSArray* objectIDs = [self objectIDsFromHelperObjectIDs: ids others: nil];
    if (0 < [objectIDs count])
	{
		//See above.
		NSString* key = [self key];
		ExpectL (mOwner && key);

		[mOwner willChangeValueForKey: key];
        [self handleRemovedObjects: [mContext registeredObjectsWithIDs: objectIDs]];
		[mOwner didChangeValueForKey: key];
	}
}

- (void) updatedObjectsWithIDs: (NSArray *) ids
{
    NSMutableArray* removedIDs = [NSMutableArray arrayWithCapacity: [ids count]];
    NSArray* addedIDs = [self objectIDsFromHelperObjectIDs: ids others: removedIDs];
	if (0 < [removedIDs count] || 0 < [addedIDs count])
	{
		//See above.
		NSString* key = [self key];
		ExpectL (mOwner && key);

		[mOwner willChangeValueForKey: key];
		if (0 < [removedIDs count])
			[self handleRemovedObjects: [mContext registeredObjectsWithIDs: removedIDs]];
		if (0 < [addedIDs count])
			[self handleAddedObjects: [mContext faultsWithIDs: addedIDs]];
		[mOwner didChangeValueForKey: key];
	}
}

@end
