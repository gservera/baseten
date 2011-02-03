//
// BXPGQueryHandler.m
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

#import "BXPGQueryHandler.h"
#import "BXPredicateVisitor.h"
#import "BXPGFromItem.h"
#import "BXHOM.h"
#import "BXRelationshipDescriptionPrivate.h"
#import "BXForeignKey.h"

NSString* kBXPGExceptionCollectAllNoneNotAllowed = @"kBXPGExceptionCollectAllNoneNotAllowed";
NSString* kBXPGExceptionInternalInconsistency = @"kBXPGExceptionInternalInconsistency";


@implementation BXPGExceptionCollectAllNoneNotAllowed
@end


@implementation BXPGExceptionInternalInconsistency
@end


@implementation BXPGQueryHandler
- (id) init
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

+ (void) willCollectAllNone
{
	[BXPGExceptionCollectAllNoneNotAllowed raise: kBXPGExceptionCollectAllNoneNotAllowed 
										  format: @"Collect all / none not allowed here."];
}

+ (void) beginQuerySpecific: (BXPGPredicateVisitor *) visitor predicate: (NSPredicate *) predicate
{
}

+ (void) endQuerySpecific: (BXPGPredicateVisitor *) visitor predicate: (NSPredicate *) predicate
{
}
@end


@implementation BXPGSelectQueryHandler
+ (void) willCollectAllNone
{
	//Don't raise the exception.
}
@end


@implementation BXPGUpdateDeleteQueryHandler
+ (void) beginQuerySpecific: (BXPGPredicateVisitor *) visitor predicate: (NSPredicate *) predicate
{
}

+ (void) endQuerySpecific: (BXPGPredicateVisitor *) visitor predicate: (NSPredicate *) predicate
{
	BXPGRelationAliasMapper* mapper = [visitor relationAliasMapper];
	BXPGRelationshipFromItem* fromItem = [mapper firstFromItem];
	
	BXRelationshipDescription* rel = [fromItem relationship];	
	NSArray* conditions = [rel BXPGVisitRelationship: (id) self fromItem: fromItem];
	[[visitor currentFrame] addObjectsFromArray: conditions];
	NSString* joined = [[visitor currentFrame] componentsJoinedByString: @" AND "];
	[visitor removeFrame];
	[visitor addToFrame: [NSString stringWithFormat: @"(%@)", joined]];
}

+ (id) visitSimpleRelationship: (BXPGRelationshipFromItem *) fromItem
{
	BXRelationshipDescription* relationship = [fromItem relationship];
	NSString* src = [[fromItem previous] alias];
	NSString* dst = [fromItem alias];

	id <BXForeignKey> fkey = [relationship foreignKey];
	id retval = BXPGConditions (src, dst, fkey, ! [relationship isInverse]);
	return retval;
}

+ (id) visitManyToManyRelationship: (BXPGHelperTableRelationshipFromItem *) fromItem
{	
	BXManyToManyRelationshipDescription* relationship = [fromItem relationship];
	NSString* srcAlias = [[fromItem previous] alias];
	NSString* dstAlias = [fromItem alias];
	id <BXForeignKey> fkey = [relationship foreignKey];
	id retval = BXPGConditions (srcAlias, dstAlias, fkey, YES);
	return retval;
}
@end
