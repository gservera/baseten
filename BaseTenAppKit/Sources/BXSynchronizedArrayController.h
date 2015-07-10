//
// BXSynchronizedArrayController.h
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

@import Cocoa;
#import <BaseTenAppKit/BXControllerProtocol.h>

@class BXDatabaseContext;
@class BXEntityDescription;


@interface BXSynchronizedArrayController : NSArrayController <NSCoding>
{
	/** \brief An NSWindow to which sheets are attached. */
    IBOutlet NSWindow* modalWindow;
    
	id mBXContent;
    
    BOOL mChanging;
	BOOL mShouldAddToContent;
}

- (NSArray *) selectedObjectIDs;

- (void) setBXContent: (id) anObject;
- (id) createObject: (NSError **) outError;
- (NSDictionary *) valuesForBoundRelationship;

/** The entity used by this `BXSynchronizedArrayController`. */
@property (nonatomic, weak) BXEntityDescription *entityDescription;
/** The database context. */
@property (nonatomic, strong) IBOutlet BXDatabaseContext *databaseContext;
/** The database object class name for this controller. */
@property (nonatomic, copy) NSString *databaseObjectClassName;
/** The database object table name for this controller. */
@property (nonatomic, copy) NSString *tableName;
/** The database object schema name for this controller. */
@property (nonatomic, copy) NSString *schemaName;

/**
 * Whether the receiver begins a transaction for each editing session.
 *
 * Sets whether the receiver asks its database context to begin a transaction
 * to lock the corresponding row when each editing session begins. Regardless of
 * the context setting for sending lock notifications, other BaseTen clients will
 * always be notified. When editing ends, the transaction will end as well. This
 * is determined from calls to -objectDidBeginEditing: and -objectDidEndEditing:
 * declared in NSEditor protocol. The default is YES.
 * \see BXDatabaseContext::setSendsLockQueries:
 */
@property (nonatomic, assign) BOOL locksRowsOnBeginEditing;

/**
 * \brief Set whether this controller fetches automatically.
 *
 * This causes the content to be fetched automatically
 * when the array controller receives a connection notification or
 * the array controller's database context is set and is already
 * connected.
 * \note Controllers the content of which is bound to other
 *       BXSynchronizedArrayControllers should not fetch on connect.
 * \see #setDatabaseContext:
 */
@property (nonatomic, assign) BOOL fetchesAutomatically;
@end

