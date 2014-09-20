//
// BXEntityDescription.h
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

#import <Foundation/Foundation.h>
#import <BaseTen/BXAbstractDescription.h>
#import <BaseTen/BXConstants.h>


@class BXDatabaseContext;
@class BXDatabaseObjectID;


enum BXEntityFlag
{
	kBXEntityNoFlag					= 0,
	kBXEntityIsEnabled				= 1 << 0, //BaseTen enabling
	kBXEntityIsValidated			= 1 << 1,
	kBXEntityIsView					= 1 << 2,
	kBXEntityGetsChangedByTriggers	= 1 << 3  //Testing for now
};

@interface BXEntityDescription : BXAbstractDescription <NSCopying, NSCoding>
{
    NSURL*                  mDatabaseURI;
    NSString*               mSchemaName;
    Class                   mDatabaseObjectClass;
	NSDictionary*			mAttributes;
    NSDictionary*			mRelationships;
	NSLock*					mValidationLock;

    id                      mObjectIDs;    
    id                      mSuperEntities;
    id                      mSubEntities;
	id						mFetchedSuperEntities; //FIXME: merge with the previous two.
    enum BXEntityFlag       mFlags;
	enum BXEntityCapability mCapabilities;
}

- (NSURL *) databaseURI;
- (NSURL *) entityURI;
- (NSString *) schemaName;
- (BOOL) isEqual: (BXEntityDescription *) desc;
- (NSUInteger) hash;
- (void) setDatabaseObjectClass: (Class) cls;
- (Class) databaseObjectClass;
- (NSDictionary *) attributesByName;
- (NSArray *) primaryKeyFields;
- (NSArray *) fields;
- (BOOL) isView;
- (NSArray *) objectIDs;
- (NSComparisonResult) compare: (BXEntityDescription *) anotherEntity;
- (NSComparisonResult) caseInsensitiveCompare: (BXEntityDescription *) anotherEntity;
- (BOOL) isValidated;
- (NSDictionary *) relationshipsByName;
- (NSDictionary *) propertiesByName;
- (BOOL) hasCapability: (enum BXEntityCapability) aCapability;
- (BOOL) isEnabled;
   
- (void) inherits: (NSArray *) entities;
- (void) addSubEntity: (BXEntityDescription *) entity;
- (id) inheritedEntities;
- (id) subEntities;
- (void) viewGetsUpdatedWith: (NSArray *) entities;
- (id) viewsUpdated;
- (BOOL) getsChangedByTriggers;
- (void) setGetsChangedByTriggers: (BOOL) flag DEPRECATED_ATTRIBUTE;
@end
