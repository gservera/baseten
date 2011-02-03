//
// BXPGSQLFunction.m
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

#import "BXPGSQLFunction.h"
#import "BXPGExpressionValueType.h"


@interface BXPGCountAggregate : BXPGSQLFunction
{
}
@end


@implementation BXPGCountAggregate
- (NSInteger) cardinality
{
	return 0;
}

- (void) BXPGVisitKeyPathComponent: (id <BXPGExpressionVisitor>) visitor
{
	[visitor visitCountAggregate: self];
}
@end


@interface BXPGArrayCountFunction : BXPGSQLFunction
{
	NSInteger mCardinality;
}
- (id) initWithCardinality: (NSInteger) c;
@end


@implementation BXPGArrayCountFunction
- (id) initWithCardinality: (NSInteger) c
{
	if ((self = [super init]))
	{
		mCardinality = c;
	}
	return self;
}

- (NSInteger) cardinality
{
	return mCardinality - 1;
}

- (void) BXPGVisitKeyPathComponent: (id <BXPGExpressionVisitor>) visitor
{
	[visitor visitArrayCountFunction: self];
}
@end


@implementation BXPGSQLFunction
+ (id) function
{
	if (self == [BXPGSQLFunction class])
		[self doesNotRecognizeSelector: _cmd];
	
	id retval = [[[self alloc] init] autorelease];
	return retval;
}

+ (id) functionNamed: (NSString *) key valueType: (BXPGExpressionValueType *) valueType
{
	id retval = nil;
	if ([@"@count" isEqualToString: key])
	{
		if (1 == [valueType arrayCardinality])
			retval = [[[BXPGArrayCountFunction alloc] initWithCardinality: 1] autorelease];
		else if (0 < [valueType relationshipCardinality])
			retval = [[[BXPGCountAggregate alloc] init] autorelease];
	}
	return retval;
}

- (NSInteger) cardinality
{
	return 0;
}

- (void) BXPGVisitKeyPathComponent: (id <BXPGExpressionVisitor>) visitor
{
	[self doesNotRecognizeSelector: _cmd];
}
@end



@implementation BXPGSQLArrayAccumFunction
- (NSInteger) cardinality
{
	return 0;
}

- (void) BXPGVisitKeyPathComponent: (id <BXPGExpressionVisitor>) visitor
{
	[visitor visitArrayAccumFunction: self];
}
@end
