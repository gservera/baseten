//
// BXPGFromItem.h
// BaseTen
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXPGExpressionVisitor.h>


@interface BXPGFromItem : NSObject 
{
	NSString* mAlias;
}
- (BXEntityDescription *) entity;
- (NSString *) alias;
- (void) setAlias: (NSString *) aString;
@end


@interface BXPGPrimaryRelationFromItem : BXPGFromItem
{
	BXEntityDescription* mEntity;
}
- (void) setEntity: (BXEntityDescription *) anEntity;
- (NSString *) BXPGVisitFromItem: (id <BXPGFromItemVisitor>) visitor;
@end


@interface BXPGRelationshipFromItem : BXPGFromItem
{
	BXRelationshipDescription* mRelationship;
	BXPGFromItem* mPrevious;
}
- (BXRelationshipDescription *) relationship;
- (void) setRelationship: (BXRelationshipDescription *) aRel;
- (BXPGFromItem *) previous;
- (void) setPrevious: (BXPGFromItem *) anItem;

- (NSString *) BXPGVisitFromItem: (id <BXPGFromItemVisitor>) visitor;
@end


@interface BXPGHelperTableRelationshipFromItem : BXPGRelationshipFromItem
{
	NSString* mHelperAlias;
}
- (NSString *) helperAlias;
- (void) setHelperAlias: (NSString *) aString;

@end

@interface BXPGHelperTableRelationshipFromItem (OverriddenMethods)
- (BXManyToManyRelationshipDescription *) relationship;
@end
