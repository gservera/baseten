//
// BXPGExpressionVisitor.h
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
#import <BaseTen/BXPGVisitor.h>

@class BXPGSQLFunction;
@class BXManyToManyRelationshipDescription;
@class BXPGLeftJoinFromItem;
@class BXPGPrimaryRelationFromItem;
@class BXPGFromItem;
@class BXAttributeDescription;
@class BXRelationshipDescription;
@class PGTSConnection;


@protocol BXPGExpressionVisitor <NSObject>
- (void) visitCountAggregate: (BXPGSQLFunction *) sqlFunction;
- (void) visitArrayCountFunction: (BXPGSQLFunction *) sqlFunction;
- (void) visitAttribute: (BXAttributeDescription *) attr;
- (void) visitRelationship: (BXRelationshipDescription *) rel;
- (void) visitArrayAccumFunction: (BXPGSQLFunction *) sqlFunction;
@end


@interface BXPGExpressionVisitor : BXPGVisitor 
{
	NSMutableString* mSQLExpression;
	NSMutableArray* mComponents;
	PGTSConnection* mConnection; //For escaping strings.
}

- (NSString *) beginWithKeyPath: (NSArray *) components;
- (PGTSConnection *) connection;
- (void) setConnection: (PGTSConnection *) conn;
@end


@interface BXPGExpressionVisitor (BXPGExpressionVisitor) <BXPGExpressionVisitor>
@end
