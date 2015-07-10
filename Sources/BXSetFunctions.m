//
// BXSetFunctions.m
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

#import "BXSetFunctions.h"
#import <CoreData/CoreData.h>


static BOOL
EqualRelationship (void const * const value1, void const * const value2, NSUInteger (*size)(void const *item))
{
	BOOL retval = NO;
	NSRelationshipDescription* r1 = (id) value1;
	NSRelationshipDescription* r2 = (id) value2;
	
	NSString *n1 = nil, *n2 = nil;
	@synchronized (r1)
	{
		n1 = [r1 name];
	}
	@synchronized (r2)
	{
		n2 = [r2 name];
	}
	
	if ([n1 isEqualToString: n2])
	{
		NSEntityDescription *e1 = nil, *e2 = nil;
		@synchronized (r1)
		{
			e1 = [r1 entity];
		}
		@synchronized (r2)
		{
			e2 = [r2 entity];
		}
		
		if ([e1 isEqual: e2])
			retval = YES;
	}
	return retval;
}


#if defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE
static Boolean
EqualRelationshipSetFn (void const * const value1, void const * const value2)
{
	return (EqualRelationship (value1, value2, NULL) ? true : false);
}



static CFSetCallBacks stNonRetainedSetCallbacks = {
	0,
	NULL,
	NULL,
	NULL,
	&CFEqual,
	&CFHash
};


static CFSetCallBacks stNSRDSetCallbacks = {
	0,
	NULL,
	NULL,
	NULL,
	&EqualRelationshipSetFn,
	&CFHash
};
#endif


id
BXSetCreateMutableWeakNonretaining ()
{
#if defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE
	return (id) CFSetCreateMutable (kCFAllocatorDefault, 0, &stNonRetainedSetCallbacks);
#else
	return [[NSHashTable weakObjectsHashTable] retain];
#endif
}


id
BXSetCreateMutableStrongRetainingForNSRD ()
{
#if defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE
	return (id) CFSetCreateMutable (kCFAllocatorDefault, 0, &stNSRDSetCallbacks);
#else
	NSPointerFunctionsOptions options = NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality;
	NSPointerFunctions *functions = [[NSPointerFunctions alloc] initWithOptions: options];
	[functions setIsEqualFunction: &EqualRelationship];

	id retval = [[NSHashTable alloc] initWithPointerFunctions: functions capacity: 0];
	[functions release];
	
	return retval;
#endif
}
