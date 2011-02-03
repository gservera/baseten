//
// BXPGSQLFunction.h
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
#import <BaseTen/BXPredicateVisitor.h>
#import <BaseTen/BXPGExpressionVisitor.h>
#import <BaseTen/BXPGExpressionValueType.h>


@interface BXPGSQLFunction : NSObject 
{
}
+ (id) function;
+ (id) functionNamed: (NSString *) key valueType: (BXPGExpressionValueType *) valueType;
- (void) BXPGVisitKeyPathComponent: (id <BXPGExpressionVisitor>) visitor;
- (NSInteger) cardinality;
@end


@interface BXPGSQLArrayAccumFunction : BXPGSQLFunction
{
}
@end
