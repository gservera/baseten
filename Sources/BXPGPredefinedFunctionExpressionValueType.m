//
// BXPGPredefinedFunctionExpressionValueType.m
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

#import "BXPGPredefinedFunctionExpressionValueType.h"
#import "BXPredicateVisitor.h"


@implementation BXPGPredefinedFunctionExpressionValueType
- (id) initWithFunctionName: (NSString *) functionName arguments: (NSArray *) arguments cardinality: (NSInteger) cardinality
{
	if ((self = [super initWithValue: functionName cardinality: cardinality]))
	{
		mArguments = [arguments retain];
	}
	return self;
}

+ (id) typeWithFunctionName: (NSString *) functionName arguments: (NSArray *) arguments cardinality: (NSInteger) cardinality
{
	return [[[self alloc] initWithFunctionName: functionName arguments: arguments cardinality: cardinality] autorelease];
}

- (void) dealloc
{
	[mArguments release];
	[super dealloc];
}

- (NSString *) expressionSQL: (id <BXPGExpressionHandler>) visitor
{
	return [visitor handlePGPredefinedFunctionExpressionValue: self];
}

- (NSArray *) arguments
{
	return mArguments;
}
@end
