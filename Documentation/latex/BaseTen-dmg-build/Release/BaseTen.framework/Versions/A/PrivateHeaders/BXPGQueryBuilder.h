//
// BXPGQueryBuilder.h
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
@class BXDatabaseObject;
@class BXPGPredicateVisitor;
@class BXPGConstantParameterMapper;
@class PGTSConnection;
@class BXPGRelationAliasMapper;
@class BXPGFromItem;
@class BXEntityDescription;


enum BXPGQueryType
{
	kBXPGQueryTypeNone = 0,
	kBXPGQueryTypeSelect,
	kBXPGQueryTypeUpdate,
	kBXPGQueryTypeInsert,
	kBXPGQueryTypeDelete
};


/**
 * \internal
 * \brief A facade for the predicate etc. handling classes.
 */
@interface BXPGQueryBuilder : NSObject 
{
	BXPGPredicateVisitor* mPredicateVisitor;
	BXPGRelationAliasMapper* mRelationMapper;
	BXPGFromItem* mPrimaryRelation;
	enum BXPGQueryType mQueryType;
}
- (BXPGFromItem *) primaryRelation;
- (void) addPrimaryRelationForEntity: (BXEntityDescription *) entity;

- (NSString *) addParameter: (id) value;
- (NSArray *) parameters;

- (NSString *) fromClause;
- (NSString *) target;
- (NSString *) fromClauseForSelect;

- (struct bx_predicate_st) whereClauseForPredicate: (NSPredicate *) predicate 
														   object: (BXDatabaseObject *) object;
- (struct bx_predicate_st) whereClauseForPredicate: (NSPredicate *) predicate 
														   entity: (BXEntityDescription *) entity 
													   connection: (PGTSConnection *) connection;
- (void) setQueryType: (enum BXPGQueryType) queryType;
- (void) reset;
@end
