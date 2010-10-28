//
// BXSetFunctions.m
// BaseTen
//
// Copyright (C) 2008-2010 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://www.karppinen.fi/baseten/licensing/ or by contacting
// us at sales@karppinen.fi. Without an additional license, this software
// may be distributed only in compliance with the GNU General Public License.
//
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License, version 2.0,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
// $Id$
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


id
BXSetCreateMutableWeakNonretaining ()
{
#if defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE
	return (id) CFSetCreateMutable (kCFAllocatorDefault, 0, &stNonRetainedSetCallbacks);
#else
	return [[NSHashTable hashTableWithWeakObjects] retain];
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
