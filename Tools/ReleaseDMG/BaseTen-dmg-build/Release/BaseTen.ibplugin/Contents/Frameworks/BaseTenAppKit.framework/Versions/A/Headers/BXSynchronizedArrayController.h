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

#import <Cocoa/Cocoa.h>
#import <BaseTenAppKit/BXControllerProtocol.h>

@class BXDatabaseContext;
@class BXEntityDescription;


@interface BXSynchronizedArrayController : NSArrayController
{
	/** \brief The database context. */
	IBOutlet BXDatabaseContext* databaseContext;
	/** \brief An NSWindow to which sheets are attached. */
    IBOutlet NSWindow* modalWindow;
        
    BXEntityDescription* mEntityDescription; //Weak
	id mBXContent;
	NSString* mContentBindingKey;
    
    //For the IB Palette
    NSString* mSchemaName;
    NSString* mTableName;
    NSString* mDBObjectClassName;

    BOOL mFetchesAutomatically;
    BOOL mChanging;
	BOOL mShouldAddToContent;
	BOOL mLocksRowsOnBeginEditing;
}

- (NSString *) schemaName;
- (void) setSchemaName: (NSString *) aSchemaName;
- (NSString *) tableName;
- (void) setTableName: (NSString *) aTableName;
- (NSString *) databaseObjectClassName;
- (void) setDatabaseObjectClassName: (NSString *) aDBObjectClassName;

- (BXDatabaseContext *) databaseContext;
- (void) setDatabaseContext: (BXDatabaseContext *) ctx;
- (BXEntityDescription *) entityDescription;
- (void) setEntityDescription: (BXEntityDescription *) desc;
- (BOOL) fetchesAutomatically;
- (void) setFetchesAutomatically: (BOOL) aBool;
- (BOOL) locksRowsOnBeginEditing;
- (void) setLocksRowsOnBeginEditing: (BOOL) aBool;
- (NSArray *) selectedObjectIDs;

- (void) setBXContent: (id) anObject;
- (id) createObject: (NSError **) outError;
- (NSDictionary *) valuesForBoundRelationship;

- (BOOL) fetchesOnConnect DEPRECATED_ATTRIBUTE;
- (void) setFetchesOnConnect: (BOOL) aBool DEPRECATED_ATTRIBUTE;
@end


@interface BXSynchronizedArrayController (NSCoding) <NSCoding>
@end
