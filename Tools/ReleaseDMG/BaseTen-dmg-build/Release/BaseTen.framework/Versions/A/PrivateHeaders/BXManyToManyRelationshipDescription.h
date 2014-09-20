//
// BXManyToManyRelationshipDescription.h
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

#import <Foundation/Foundation.h>
#import <BaseTen/BXRelationshipDescription.h>

@class BXDatabaseObject;
@class BXPGHelperTableRelationshipFromItem;
@protocol BXPGRelationshipVisitor;


@interface BXManyToManyRelationshipDescription : BXRelationshipDescription 
{
	id <BXForeignKey> mDstForeignKey;
	BXEntityDescription* mHelperEntity;
}

- (id <BXForeignKey>) dstForeignKey;
- (void) setDstForeignKey: (id <BXForeignKey>) aKey;
- (BXEntityDescription *) helperEntity;
- (void) setHelperEntity: (BXEntityDescription *) anEntity;
- (NSPredicate *) filterPredicateFor: (BXDatabaseObject *) object;
- (void) iterateForeignKey: (void (*)(NSString*, NSString*, void*)) callback context: (void *) ctx;
- (void) iterateDstForeignKey: (void (*)(NSString*, NSString*, void*)) callback context: (void *) ctx;
@end


@interface BXManyToManyRelationshipDescription (BXPGRelationAliasMapper)
- (id) BXPGVisitRelationship: (id <BXPGRelationshipVisitor>) visitor fromItem: (BXPGHelperTableRelationshipFromItem *) fromItem;
@end