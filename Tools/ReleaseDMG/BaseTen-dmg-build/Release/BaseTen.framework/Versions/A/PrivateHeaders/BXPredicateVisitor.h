//
// BXPredicateVisitor.h
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
#import <BaseTen/BaseTen.h>
#import <BaseTen/PGTSConnection.h>
#import <BaseTen/BXPGVisitor.h>
#import <BaseTen/BXPGQueryBuilder.h>


@class BXPGExpressionVisitor;
@class BXPGConstantParameterMapper;
@class BXPGExpressionValueType;
@class BXPGPredefinedFunctionExpressionValueType;


@protocol BXPGPredicateVisitor <NSObject>
- (void) visitUnknownPredicate: (NSPredicate *) predicate;
- (void) visitTruePredicate: (NSPredicate *) predicate;
- (void) visitFalsePredicate: (NSPredicate *) predicate;
- (void) visitAndPredicate: (NSCompoundPredicate *) predicate;
- (void) visitOrPredicate: (NSCompoundPredicate *) predicate;
- (void) visitNotPredicate: (NSCompoundPredicate *) predicate;
- (void) visitComparisonPredicate: (NSComparisonPredicate *) predicate;

- (BXPGExpressionValueType *) visitConstantValueExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitEvaluatedObjectExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitVariableExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitKeyPathExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitFunctionExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitAggregateExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitSubqueryExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitUnionSetExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitIntersectSetExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitMinusSetExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitBlockExpression: (NSExpression *) expression;
- (BXPGExpressionValueType *) visitUnknownExpression: (NSExpression *) expression;
@end


@protocol BXPGExpressionHandler <NSObject>
- (NSString *) handlePGConstantExpressionValue: (id) value;
- (NSString *) handlePGKeyPathExpressionValue: (NSArray *) keyPath;
- (NSString *) handlePGAggregateExpressionValue: (NSArray *) valueTree;
- (NSString *) handlePGPredefinedFunctionExpressionValue: (BXPGPredefinedFunctionExpressionValueType *) valueType;
@end


struct bx_predicate_st 
{
	NSString* p_where_clause;
	BOOL p_results_require_filtering;
};


@interface BXPGPredicateVisitor : BXPGVisitor
{
	BXDatabaseObject* mObject;
	BXEntityDescription* mEntity;
	NSMutableDictionary* mContext; //For evaluating expressions.
	BXPGExpressionVisitor* mExpressionVisitor;
	BXPGConstantParameterMapper* mParameterMapper;
	Class mQueryHandler;
	
	NSMutableArray* mStack; //Array of NSMutableArrays.
	NSInteger mStackIdx;
	BOOL mCollectAllState;
	BOOL mWillCollectAll;
}

- (void) setEntity: (BXEntityDescription *) entity;
- (void) setObject: (BXDatabaseObject *) anObject;
- (void) setConnection: (PGTSConnection *) connection;
- (void) setQueryType: (enum BXPGQueryType) queryType;

- (void) addFrame;
- (void) removeFrame;
- (NSMutableArray *) currentFrame;
- (void) addToFrame: (id) value;

- (struct bx_predicate_st) beginWithPredicate: (NSPredicate *) predicate;

- (BXPGConstantParameterMapper *) constantParameterMapper;
- (BXPGExpressionVisitor *) expressionVisitor;
@end


@interface BXPGPredicateVisitor (BXPGPredicateVisitor) <BXPGPredicateVisitor>
@end


@interface BXPGPredicateVisitor (BXPGExpressionHandler) <BXPGExpressionHandler>
@end
