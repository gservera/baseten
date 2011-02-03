//
// BXVerbatimExpressionValue.m
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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

#import "BXVerbatimExpressionValue.h"
#import "BXLogger.h"


@implementation BXVerbatimExpressionValue
+ (id) valueWithString: (NSString *) aString
{
	id retval = [[[self alloc] initWithString: aString] autorelease];
	return retval;
}

- (id) initWithString: (NSString *) aString
{
	if ((self = [super init]))
	{
		mValue = [aString retain];
	}
	return self;
}

- (void) dealloc
{
	[mValue release];
	[super dealloc];
}

- (enum BXExpressionValueType) getBXExpressionValue: (id *) outValue usingContext: (NSMutableDictionary *) context
{
	ExpectR (outValue, kBXExpressionValueTypeUndefined);
	*outValue = mValue;
    return kBXExpressionValueTypeVerbatim;
}
@end
