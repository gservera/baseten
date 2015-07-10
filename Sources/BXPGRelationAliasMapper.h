//
// BXPGRelationAliasMapper.h
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
#import <BaseTen/BXLogger.h>


@class BXPGFromItem;
@class BXEntityDescription;
@class BXRelationshipDescription;
@class BXPGPrimaryRelationFromItem;
@class BXPGRelationshipFromItem;
@class BXPGHelperTableRelationshipFromItem;
@class BXManyToManyRelationshipDescription;
@protocol BXForeignKey;


BX_EXPORT NSArray* BXPGConditions (NSString* alias1, NSString* alias2, id <BXForeignKey> fkey, BOOL reverseNames);


@protocol BXPGFromItemVisitor <NSObject>
- (NSString *) visitPrimaryRelation: (BXPGPrimaryRelationFromItem *) fromItem;
- (NSString *) visitRelationshipJoinItem: (BXPGRelationshipFromItem *) fromItem;
@end


@protocol BXPGRelationshipVisitor <NSObject>
- (NSString *) visitSimpleRelationship: (BXPGRelationshipFromItem *) fromItem;
- (NSString *) visitManyToManyRelationship: (BXPGHelperTableRelationshipFromItem *) fromItem;
@end


@interface BXPGRelationAliasMapper : NSObject 
{
	BXPGPrimaryRelationFromItem* mPrimaryRelation;
	NSMutableArray* mFromItems;
	NSMutableDictionary* mUsedAliases;
	NSMutableArray* mCurrentFromItems;
	
	BOOL mIsFirstInUpdate;
}

- (BXPGPrimaryRelationFromItem *) primaryRelation;
- (void) accept;
- (void) resetCurrent;
- (void) resetAll;

- (NSString *) fromClauseForSelect;
- (NSString *) fromOrUsingClause;
- (NSString *) target;

- (NSString *) addAliasForEntity: (BXEntityDescription *) entity;
- (BXPGPrimaryRelationFromItem *) addPrimaryRelationForEntity: (BXEntityDescription *) entity;
- (BXPGRelationshipFromItem *) addFromItemForRelationship: (BXRelationshipDescription *) rel;
- (BXPGRelationshipFromItem *) previousFromItem;
- (BXPGRelationshipFromItem *) firstFromItem;
@end


@interface BXPGRelationAliasMapper (BXPGFromItemVisitor) <BXPGFromItemVisitor>
@end


@interface BXPGRelationAliasMapper (BXPGRelationshipVisitor) <BXPGRelationshipVisitor>
@end
