//
// BXRelationshipDescriptionPrivate.h
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

#import <BaseTen/BXRelationshipDescription.h>
#import <BaseTen/BXPGRelationAliasMapper.h>

@class BXForeignKey;
@class BXDatabaseObject;

@interface BXRelationshipDescription (PrivateMethods)
- (id) initWithName: (NSString *) aName entity: (BXEntityDescription *) entity 
  destinationEntity: (BXEntityDescription *) destinationEntity;
- (id <BXForeignKey>) foreignKey;
- (void) setForeignKey: (id <BXForeignKey>) aKey;
- (BOOL) isInverse;
- (void) setIsInverse: (BOOL) aBool;
- (BOOL) usesRelationNames;
- (void) setUsesRelationNames: (BOOL) aBool;
- (void) setInverseName: (NSString *) aString;
- (void) setDeprecated: (BOOL) aBool;

//Remember to override these in subclasses.
- (id) registeredTargetFor: (BXDatabaseObject *) databaseObject fireFault: (BOOL) fireFault;
- (id) targetForObject: (BXDatabaseObject *) anObject error: (NSError **) error;
- (BOOL) setTarget: (id) target
		 forObject: (BXDatabaseObject *) aDatabaseObject
			 error: (NSError **) error;

- (void) iterateForeignKey: (void (*)(NSString*, NSString*, void*) )callback context: (void *) ctx;

- (void) removeAttributeDependency;
- (void) makeAttributeDependency;
@end


@interface BXRelationshipDescription (BXPGRelationAliasMapper)
- (id) BXPGVisitRelationship: (id <BXPGRelationshipVisitor>) visitor fromItem: (BXPGRelationshipFromItem *) fromItem;
@end
