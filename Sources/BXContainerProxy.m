//
// BXArrayProxy.m
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

#import "BXContainerProxy.h"
#import "BXDatabaseContext.h"
#import "BXConstants.h"
#import "BXConstantsPrivate.h"
#import "BXLogger.h"
#import "BXEnumerate.h"
#import "NSArray+BaseTenAdditions.h"


/**
 * \brief A generic self-updating container proxy.
 * \ingroup auto_containers
 */
@implementation BXContainerProxy

- (id) BXInitWithArray: (NSMutableArray *) anArray NS_RETURNS_RETAINED
{
    mIsMutable = YES;
    mChanging = NO;
    return self;
}

- (void) dealloc
{
    [[mContext notificationCenter] removeObserver: self];
    [mContainer release];    
    [mContext release];
    [mKey release];
    [mFilterPredicate release];
    [mEntity release];
    [super dealloc];
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"<%@: %p \n (%@ (%p) => %@): \n %@>", 
		NSStringFromClass ([self class]), self, NSStringFromClass ([mOwner class]), mOwner, mKey, mContainer];
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL) aSelector
{
	Expect (mContainer);
    NSMethodSignature* retval = nil;
    if (mIsMutable)
        retval = [mContainer methodSignatureForSelector: aSelector];
    else
    {
        //Only allow the non-mutating methods
		BXAssertLog (Nil != mNonMutatingClass, @"Expected mimiced class to be set.");
        retval = [mNonMutatingClass instanceMethodSignatureForSelector: aSelector];
    }
    return retval;
}

- (void) forwardInvocation: (NSInvocation *) anInvocation
{
    [anInvocation invokeWithTarget: mContainer];
}

- (BOOL) isEqual: (id) anObject
{
    return [mContainer isEqual: anObject];
}

- (id) copyWithZone: (NSZone *) aZone
{
	//Retain on copy.
	return [self retain];
}

//FIXME: need we this?
#if 0
- (id) mutableCopyWithZone: (NSZone *) aZone
{
	BXContainerProxy* retval = [[self class] allocWithZone: aZone];
	retval->mContext = [mContext retain];
	retval->mContainer = [mContainer mutableCopyWithZone: aZone];
	retval->mNonMutatingClass = mNonMutatingClass;
	retval->mFilterPredicate = [mFilterPredicate retain];
	retval->mEntity = [mEntity copyWithZone: aZone];
	retval->mIsMutable = mIsMutable;
	retval->mChanging = mChanging;
	return retval;
}
#endif

- (void) filterObjectsForUpdate: (NSArray *) objects 
                          added: (NSMutableArray **) added 
                        removed: (NSMutableArray **) removed
{
    BXAssertVoidReturn (NULL != added && NULL != removed, 
						@"Expected given pointers not to have been NULL.");
    if (nil == mFilterPredicate)
    {
        //If filter predicate is not set, then every object in the entity should be added.
        *added = [[objects mutableCopy] autorelease];
    }
    else
    {
        //Otherwise, separate the objects using the filter predicate.
		NSMutableDictionary* ctx = [self substitutionVariables];
        *removed = [NSMutableArray arrayWithCapacity: [objects count]];
        *added   = [objects BXFilteredArrayUsingPredicate: mFilterPredicate others: *removed substitutionVariables: ctx];
    }    
}

- (NSMutableDictionary *) substitutionVariables
{
	NSMutableDictionary* retval = nil;
	id owner = [self owner];
	if (owner)
		retval = [NSMutableDictionary dictionaryWithObject: owner forKey: kBXOwnerObjectVariableName];
	else
		retval = [NSMutableDictionary dictionary];
	return retval;
}
@end


@implementation BXContainerProxy (Notifications)

- (void) addedObjects: (NSNotification *) notification
{
    if (NO == mChanging)
    {
        NSDictionary* userInfo = [notification userInfo];
        BXAssertVoidReturn (mContext == [userInfo objectForKey: kBXContextKey], 
                              @"Expected to observe another context.");
        
        NSArray* ids = [userInfo objectForKey: kBXObjectIDsKey];        
        BXLogDebug (@"Adding object ids: %@", ids);
        [self addedObjectsWithIDs: ids];
    }
}

- (void) updatedObjects: (NSNotification *) notification
{
    if (NO == mChanging)
    {
        NSDictionary* userInfo = [notification userInfo];
        BXAssertVoidReturn (mContext == [userInfo objectForKey: kBXContextKey], 
                              @"Expected to observe another context.");
        
        NSArray* ids = [userInfo objectForKey: kBXObjectIDsKey];
        BXLogDebug (@"Updating for object ids: %@", ids);
        [self updatedObjectsWithIDs: ids];
    }
}

- (void) deletedObjects: (NSNotification *) notification
{
    if (NO == mChanging)
    {
        NSDictionary* userInfo = [notification userInfo];
        BXAssertVoidReturn (mContext == [userInfo objectForKey: kBXContextKey], 
                              @"Expected to observe another context.");
        
        NSArray* ids = [userInfo objectForKey: kBXObjectIDsKey];
        BXLogDebug (@"Removing object ids: %@", ids);
        [self removedObjectsWithIDs: ids];
    }
}

@end


@implementation BXContainerProxy (Callbacks)

- (void) addedObjectsWithIDs: (NSArray *) ids
{    
    NSArray* objects = [mContext faultsWithIDs: ids];
	BXLogDebug (@"Adding objects: %@", objects);
	NSMutableDictionary* ctx = [self substitutionVariables];
    if (nil != mFilterPredicate)
	{
        objects = [objects BXFilteredArrayUsingPredicate: mFilterPredicate 
												  others: nil
								   substitutionVariables: ctx];
	}
    
    //Post notifications since modifying a self-updating collection won't cause
    //value cache to be changed.
	NSString* key = [self key];
	ExpectL (mOwner && key);
	
    [mOwner willChangeValueForKey: key];    
    [self handleAddedObjects: objects];
    [mOwner didChangeValueForKey: key];
    
    BXLogDebug (@"Contents after adding: %@", mContainer);
}

- (void) removedObjectsWithIDs: (NSArray *) ids
{
    //Post notifications since modifying a self-updating collection won't cause
    //value cache to be changed.
	NSString* key = [self key];
	ExpectL (mOwner && key);

    [mOwner willChangeValueForKey: key];    
    [self handleRemovedObjects: [mContext registeredObjectsWithIDs: ids]];
    [mOwner didChangeValueForKey: key];
    BXLogDebug (@"Contents after removal: %@", mContainer);
}

- (void) updatedObjectsWithIDs: (NSArray *) ids
{
    NSArray* objects = [mContext faultsWithIDs: ids];
    NSMutableArray *addedObjects = nil, *removedObjects = nil;
    [self filterObjectsForUpdate: objects added: &addedObjects removed: &removedObjects];        

	//Remove redundant objects.
	BXEnumerate (currentObject, e, [[[addedObjects copy] autorelease] objectEnumerator])
	{
		if ([mContainer containsObject: currentObject])
			[addedObjects removeObject: currentObject];
	}
	BXEnumerate (currentObject, e, [[[removedObjects copy] autorelease] objectEnumerator])
	{
		if (! [mContainer containsObject: currentObject])
			[removedObjects removeObject: currentObject];
	}
	
	BOOL changed = (0 < [removedObjects count] || 0 < [addedObjects count]);
    
	BXLogDebug (@"Removing:\t%@", removedObjects);
	BXLogDebug (@"Adding:\t%@", addedObjects);
	
    //Post notifications since modifying a self-updating collection won't cause
    //value cache to be changed.
	if (changed)
	{
		NSString* key = [self key];
		ExpectL (mOwner && key);

		[mOwner willChangeValueForKey: key];    
		[self handleRemovedObjects: removedObjects];
		[self handleAddedObjects: addedObjects];
		[mOwner didChangeValueForKey: key];
	}
	
	BXLogDebug (@"Count after operation:\t%lu", (unsigned long)[mContainer count]);
}

- (void) handleAddedObjects: (NSArray *) objectArray
{
    BXEnumerate (currentObject, e, [objectArray objectEnumerator])
	{
		if (NO == [mContainer containsObject: currentObject])
			[mContainer addObject: currentObject];
	}
}

- (void) handleRemovedObjects: (NSArray *) objectArray
{
    BXEnumerate (currentObject, e, [objectArray objectEnumerator])
        [mContainer removeObject: currentObject];
}

@end


@implementation BXContainerProxy (Accessors)

/** \brief The container's context. */
- (BXDatabaseContext *) context
{
    return mContext; 
}

- (void) setDatabaseContext: (BXDatabaseContext *) aContext
{
    if (mContext != aContext) 
    {
        [mContext release];
        mContext = [aContext retain];
    }
}

/** \brief The container's filter predicate. */
- (NSPredicate *) filterPredicate;
{
    return mFilterPredicate;
}

- (void) setFilterPredicate: (NSPredicate *) aFilterPredicate
{
    if (mFilterPredicate != aFilterPredicate) 
    {
        [mFilterPredicate release];
        mFilterPredicate = [aFilterPredicate retain];
    }
}

- (void) fetchedForEntity: (BXEntityDescription *) entity predicate: (NSPredicate *) predicate
{
	[self setEntity: entity];
	[self setFilterPredicate: predicate];
}

- (void) setEntity: (BXEntityDescription *) entity
{
	ExpectV (mContext);
    
    //Set up the modification notification
    if (mEntity != entity) 
    {
		[mEntity release];
        mEntity = [entity retain];
        
        NSNotificationCenter* nc = [mContext notificationCenter];
		ExpectV (nc);
        [nc removeObserver: self];
        
        SEL addSelector = @selector (addedObjects:);
        SEL delSelector = @selector (deletedObjects:);
        SEL updSelector = @selector (updatedObjects:);

        [nc addObserver: self selector: addSelector name: kBXInsertEarlyNotification object: entity];
        [nc addObserver: self selector: delSelector name: kBXDeleteEarlyNotification object: entity];                    
        [nc addObserver: self selector: updSelector name: kBXUpdateEarlyNotification object: entity];
    }
}

/** \brief The container's owner. */
- (id) owner
{
	return mOwner;
}

/** 
 * \brief Set the cotainer's owner.
 *
 * NSKeyValueObserving notifications will be posted to the owner.
 * \note The owner is not retained.
 */
- (void) setOwner: (id) anObject
{
    mOwner = anObject;
}

/** \brief The owner's key for the container. */
- (NSString *) key
{
    return [[mKey copy] autorelease];
}

/** 
 * \brief Set the owner's key for the container.
 *
 * NSKeyValueObserving notifications will be posted using this key.
 */
- (void) setKey: (NSString *) aString
{
    if (mKey != aString)
    {
        [mKey release];
        mKey = [aString retain];
    }
}

@end