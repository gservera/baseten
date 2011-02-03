//
// BXPGConstantParameterMapper.m
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

#import "BXPGConstantParameterMapper.h"


@implementation BXPGConstantParameterMapper
- (id) init
{
	if ((self = [super init]))
	{
		mParameters = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[mParameters release];
	[super dealloc];
}

- (void) reset
{
	mIndex = 0;
	[mParameters removeAllObjects];
}

- (NSString *) addParameter: (id) value
{
	[mParameters addObject: value];
	mIndex++;
	NSString* retval = [NSString stringWithFormat: @"$%d", mIndex];
	return retval;
}

- (NSArray *) parameters
{
	NSArray* retval = [[mParameters copy] autorelease];
	return retval;
}
@end
