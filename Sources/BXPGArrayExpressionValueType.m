//
// BXPGArrayExpressionValueType.m
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


#import "BXPGArrayExpressionValueType.h"


@implementation BXPGArrayExpressionValueType
+ (id) typeWithValue: (id) value cardinality: (NSInteger) cardinality
{
	id retval = [[[self alloc] initWithValue: value cardinality: cardinality] autorelease];
	return retval;
}

- (id) initWithValue: (id) value cardinality: (NSInteger) cardinality
{
	if ([self class] == [BXPGArrayExpressionValueType class])
		[self doesNotRecognizeSelector: _cmd];
	
	if ((self = [super initWithValue: value]))
	{
		mArrayCardinality = cardinality;
	}
	return self;
}

- (id) initWithValue: (id) value
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

- (NSInteger) arrayCardinality
{
	return mArrayCardinality;
}
@end
