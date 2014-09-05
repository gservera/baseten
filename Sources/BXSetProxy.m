//
// BXSetProxy.m
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

#import "BXSetProxy.h"
#import "BXDatabaseContext.h"
#import "BXLogger.h"
#import "BXDatabaseObject.h"
#import "NSArray+BaseTenAdditions.h"


/**
 * \brief An NSMutableSet-style self-updating container proxy.
 * \ingroup auto_containers
 */
@implementation BXSetProxy

- (id) BXInitWithArray: (NSMutableArray *) anArray
{
    if ((self = [super BXInitWithArray: anArray]))
    {
		if (anArray)
	        mContainer = [[NSCountedSet alloc] initWithArray: anArray];
		else
			mContainer = [[NSCountedSet alloc] init];
        mNonMutatingClass = [NSSet class];
    }
    return self;
}

- (NSUInteger) countForObject: (id) anObject
{
    return [mContainer countForObject: anObject];
}

- (id) countedSet
{
    return mContainer;
}

- (id) mutableSet
{
	return mContainer;
}

- (void) addedObjectsWithIDs: (NSArray *) ids
{
    NSArray* objects = [mContext faultsWithIDs: ids];
	BXLogDebug (@"Adding objects: %@", objects);
    if (nil != mFilterPredicate)
	{
		NSMutableDictionary* ctx = [self substitutionVariables];
        objects = [objects BXFilteredArrayUsingPredicate: mFilterPredicate 
												  others: nil
								   substitutionVariables: ctx];
	}
    
	if (0 < [objects count])
	{
		NSSet* change = [NSSet setWithArray: objects];
		NSString* key = [self key];
		ExpectL (mOwner && key);

		[mOwner willChangeValueForKey: key
					  withSetMutation: NSKeyValueUnionSetMutation 
						 usingObjects: change];
		[mContainer unionSet: change];
		[mOwner didChangeValueForKey: key 
					 withSetMutation: NSKeyValueUnionSetMutation 
						usingObjects: change];
	}
	BXLogDebug (@"Contents after adding: %@", mContainer);
}

- (void) removedObjectsWithIDs: (NSArray *) ids
{
    NSMutableSet* change = [NSMutableSet setWithArray: [mContext registeredObjectsWithIDs: ids]];
	[change intersectSet: mContainer];
	if (0 < [change count])
	{
		NSString* key = [self key];
		ExpectL (mOwner && key);

		[mOwner willChangeValueForKey: key
					  withSetMutation: NSKeyValueMinusSetMutation 
						 usingObjects: change];
		[mContainer minusSet: change];
		[mOwner didChangeValueForKey: key 
					 withSetMutation: NSKeyValueMinusSetMutation 
						usingObjects: change];
	}
	BXLogDebug (@"Contents after removal: %@", mContainer);
}

- (void) updatedObjectsWithIDs: (NSArray *) ids
{
    NSMutableSet *added = nil, *removed = nil;

    {
        NSArray* objects = [mContext faultsWithIDs: ids];
        NSMutableArray *addedObjects = nil, *removedObjects = nil;
        [self filterObjectsForUpdate: objects added: &addedObjects removed: &removedObjects];
        added = [NSMutableSet setWithArray: addedObjects];
        removed = [NSMutableSet setWithArray: removedObjects];
    }
    
	//Remove redundant objects
    [added minusSet: mContainer];
    [removed intersectSet: mContainer];	    
	BXLogDebug (@"Removing:\t%@", removed);
	BXLogDebug (@"Adding:\t%@", added);
    
    //Determine the change
    NSMutableSet* changed = nil;
    NSKeyValueSetMutationKind mutation = 0;
    if (0 < [added count] && 0 == [removed count])
    {
        mutation = NSKeyValueUnionSetMutation;
        changed = added;
    }
    else if (0 == [added count] && 0 < [removed count])
    {
        mutation = NSKeyValueMinusSetMutation;
        changed = removed;
    }
    else if (0 < [added count] && 0 < [removed count])
    {
        mutation = NSKeyValueSetSetMutation;
        changed = added;
        [changed unionSet: mContainer];
        [changed minusSet: removed];
    }        
    
    if (changed)
    {
		NSString* key = [self key];
		ExpectL (mOwner && key);

        [mOwner willChangeValueForKey: key withSetMutation: mutation usingObjects: changed];
        switch (mutation)
        {
            case NSKeyValueUnionSetMutation:
                [mContainer unionSet: changed];
                break;
            case NSKeyValueMinusSetMutation:
                [mContainer minusSet: changed];
                break;
            case NSKeyValueSetSetMutation:
                [mContainer setSet: changed];
                break;
            default:
                break;
        }
        [mOwner didChangeValueForKey: key withSetMutation: mutation usingObjects: changed];
    }
	BXLogDebug (@"Count after operation:\t%lu", [mContainer count]);
}

@end
