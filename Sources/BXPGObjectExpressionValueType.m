//
// BXPGObjectExpressionValueType.m
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

#import "BXPGObjectExpressionValueType.h"
#import "PGTSFoundationObjects.h"


@implementation BXPGObjectExpressionValueType
- (id) initWithValue: (id) value
{
	if ([self class] == [BXPGObjectExpressionValueType class])
		[self doesNotRecognizeSelector: _cmd];
	
	if ((self = [super init]))
	{
		mValue = [value retain];
	}
	return self;
}

+ (id) typeWithValue: (id) value
{
	id retval = [[[self alloc] initWithValue: value] autorelease];
	return retval;
}

- (void) dealloc
{
	[mValue release];
	[super dealloc];
}

- (id) value
{
	return mValue;
}
@end
