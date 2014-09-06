//
// PGTSQuery.h
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



@class PGTSConnection;
@class PGTSQuery;
@class PGTSAbstractParameterQuery;



@protocol PGTSQueryVisitor <NSObject>
- (id) visitQuery: (PGTSQuery *) query;
- (id) visitParameterQuery: (PGTSAbstractParameterQuery *) query;
@end



@interface PGTSQuery : NSObject
{
}
- (NSString *) query;
- (int) sendQuery: (PGTSConnection *) connection;
- (id) visitQuery: (id <PGTSQueryVisitor>) visitor;
@end



@interface PGTSAbstractParameterQuery : PGTSQuery
{
	NSArray* mParameters;
}
- (NSArray *) parameters;
- (void) setParameters: (NSArray *) anArray;
- (NSUInteger) parameterCount;
@end



@interface PGTSParameterQuery : PGTSAbstractParameterQuery
{
	NSString* mQuery;
}
- (void) setQuery: (NSString *) aString;
@end
