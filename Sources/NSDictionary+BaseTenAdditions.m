//
// NSDictionary+BaseTenAdditions.m
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

#import "NSDictionary+BaseTenAdditions.h"
#import "BXEnumerate.h"


@implementation NSDictionary (BaseTenAdditions)
- (NSDictionary *) BXDeepCopy
{
	NSUInteger count = [self count];
	NSMutableArray *keys = [NSMutableArray arrayWithCapacity: count];
	NSMutableArray *vals = [NSMutableArray arrayWithCapacity: count];
	BXEnumerate (currentKey, e, [self keyEnumerator])
	{
		[keys addObject: currentKey];
		
		id copy = [[self objectForKey: currentKey] copy];
		[vals addObject: copy];
		[copy release];
	}
	
	NSDictionary *retval = [[NSDictionary alloc] initWithObjects: vals forKeys: keys];
	return retval;
}
@end
