//
// NSController+BXCocoaAdditions.m
// BaseTen
//
// Copyright 2008-2009 Marko Karppinen & Co. LLC.
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

#import <BaseTen/BaseTen.h>
#import <BaseTen/BXDatabaseContextPrivate.h>
#import "BXControllerProtocol.h"
#import "NSController+BXAppKitAdditions.h"


@implementation NSObjectController (BXCocoaAdditions)
/** 
 * \internal
 * \brief A convenience method for locking the key in the currently selected object. 
 */
- (void) BXLockKey: (NSString *) key status: (enum BXObjectLockStatus) status editor: (id) editor
{
    [self BXLockObject: [self selection] key: key status: status editor: editor];
}

- (void) BXUnlockKey: (NSString *) key editor: (id) editor
{
    [self BXUnlockObject: [self selection] key: key editor: editor];
}
@end


/**
 * \internal
 * \brief Some methods used by BaseTen in BXArrayController.
 * \ingroup baseten_appkit
 */
@implementation NSController (BXCocoaAdditions)

/** 
 * \internal
 * \brief Lock an object asynchronously. 
 */
- (void) BXLockObject: (BXDatabaseObject *) object key: (NSString *) key 
                  status: (enum BXObjectLockStatus) status editor: (id) editor
{
    BXDatabaseContext* ctx = [self BXDatabaseContext];
    
    //Replace the proxy with the real object
    if (NO == [object isKindOfClass: [BXDatabaseObject class]] || [object isProxy])
    {
        BXDatabaseObjectID* objectID = [object valueForKey: @"objectID"];
        object = [ctx registeredObjectWithID: objectID];
    }
    
    [ctx lockObject: object key: key status: status sender: self];
}

/** 
 * \internal
 * \brief Unlock an object synchronously. 
 */
- (void) BXUnlockObject: (BXDatabaseObject *) object key: (NSString *) key editor: (id) editor
{
    BXDatabaseContext* ctx = [self BXDatabaseContext];
    //Replace the proxy with the real object
    if (NO == [object isKindOfClass: [BXDatabaseObject class]] || [object isProxy])
    {
        BXDatabaseObjectID* objectID = [object valueForKey: @"objectID"];
        object = [ctx registeredObjectWithID: objectID];
    }

    [ctx unlockObject: object key: key];
}

/** 
 * \internal 
 * \brief Handle the error if a lock couldn't be acquired. 
 */
- (void) BXLockAcquired: (BOOL) lockAcquired object: (BXDatabaseObject *) receiver error: (NSError *) dbError
{
    if (NO == lockAcquired)
    {
		[self discardEditing];
		
        [self BXHandleError: dbError];
    }
}

/** 
 * \internal
 * \brief The database context. 
 */
- (BXDatabaseContext *) BXDatabaseContext
{
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: @"Insufficient functionality; use a subclass provided with the BaseTenAppKit framework instead"
                                 userInfo: nil];
    return nil;
}

/** 
 * \internal
 * \brief The window in which all the edited NSControls are. 
 */
- (NSWindow *) BXWindow
{
    return nil;
}

/**
 * \internal
 * \brief An error handler.
 */
- (void) BXHandleError: (NSError *) error
{
	NSWindow* window = [self BXWindow];
	if (window && ![window attachedSheet])
		[NSApp presentError: error modalForWindow: window delegate: nil didPresentSelector: NULL contextInfo: NULL];
	else
		[NSApp presentError: error];
}

@end