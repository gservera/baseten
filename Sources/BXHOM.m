//
// BXHOM.m
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

#import "BXHOM.h"
#import "PGTSInvocationRecorder.h"
#import "BXEnumerate.h"


static id 
VisitorTrampoline (id self, id target, SEL callback, id userInfo)
{
	id retval = nil;
	if (0 < [self count])
	{
		PGTSCallbackInvocationRecorder* recorder = [[[PGTSCallbackInvocationRecorder alloc] init] autorelease];
		[recorder setTarget: target];
		[recorder setCallbackTarget: self];
		[recorder setCallback: callback];
		[recorder setUserInfo: userInfo];
		retval = [recorder record];
	}
	return retval;
}


static id
HOMTrampoline (id self, SEL callback, id userInfo)
{
	id retval = nil;
	if (0 < [self count])
	{
		PGTSHOMInvocationRecorder* recorder = [[[PGTSHOMInvocationRecorder alloc] init] autorelease];
		[recorder setCallback: callback target: self];
		[recorder setUserInfo: userInfo];
		retval = [recorder record];
	}
	return retval;
}


static id
KeyTrampoline (id self, SEL callback, id userInfo)
{
	id retval = nil;
	if (0 < [self count])
	{
		PGTSCallbackInvocationRecorder* recorder = [[[PGTSCallbackInvocationRecorder alloc] init] autorelease];
		[recorder setCallback: callback];
		[recorder setCallbackTarget: self];
		[recorder setTarget: [[self keyEnumerator] nextObject]];
		retval = [recorder record];
	}
	return retval;
}


static void
CollectAndPerform (id self, id retval, NSInvocation* invocation, NSEnumerator* e)
{
	id currentObject = nil;
	while ((currentObject = [e nextObject]))
	{
		[invocation invokeWithTarget: currentObject];
		id collected = nil;
		[invocation getReturnValue: &collected];
		if (! collected) collected = [NSNull null];
		[retval addObject: collected];
	}
	retval = [[retval copy] autorelease];
	[invocation setReturnValue: &retval];
}


static void
CollectAndPerformD (id self, NSMutableDictionary* retval, NSInvocation* invocation, NSEnumerator* e)
{
	id currentObject = nil;
	while ((currentObject = [e nextObject]))
	{
		[invocation invokeWithTarget: currentObject];
		id collected = nil;
		[invocation getReturnValue: &collected];
		if (collected)
			[retval setObject: currentObject forKey: collected];
	}
	retval = [[retval copy] autorelease];
	[invocation setReturnValue: &retval];
}


static void
CollectAndPerformDK (id self, NSMutableDictionary* retval, NSInvocation* invocation, NSEnumerator* e)
{
	id currentObject = nil;
	while ((currentObject = [e nextObject]))
	{
		[invocation invokeWithTarget: currentObject];
		id collected = nil;
		[invocation getReturnValue: &collected];
		if (collected)
			[retval setObject: collected forKey: currentObject];
	}
	retval = [[retval copy] autorelease];
	[invocation setReturnValue: &retval];
}


static void
Do (NSInvocation* invocation, NSEnumerator* enumerator)
{
	BXEnumerate (currentObject, e, enumerator)
		[invocation invokeWithTarget: currentObject];
}


static id
SelectFunction (id sender, id retval, int (* fptr)(id))
{
	BXEnumerate (currentObject, e, [sender objectEnumerator])
	{
		if (fptr (currentObject))
			[retval addObject: currentObject];
	}
	retval = [[retval copy] autorelease];
	return retval;
}


static id
SelectFunction2 (id sender, id retval, int (* fptr)(id, void*), void* arg)
{
	BXEnumerate (currentObject, e, [sender objectEnumerator])
	{
		if (fptr (currentObject, arg))
			[retval addObject: currentObject];
	}
	retval = [[retval copy] autorelease];
	return retval;
}


static void
Visit (NSInvocation* invocation, NSEnumerator* enumerator)
{
	BXEnumerate (currentObject, e, enumerator)
	{
		[invocation setArgument: &currentObject atIndex: 2];
		[invocation invoke];
	}
}



@implementation NSSet (BXHOM)
- (void) _BX_Collect: (NSInvocation *) invocation userInfo: (Class) retclass
{
	id retval = [[[retclass alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerform (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_CollectD: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerformD (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_CollectDK: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerformDK (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_Do: (NSInvocation *) invocation userInfo: (id) anObject
{
	Do (invocation, [self objectEnumerator]);
}


- (void) _BX_Visit: (NSInvocation *) invocation userInfo: (id) userInfo
{
	Visit (invocation, [self objectEnumerator]);
}


- (id) BX_Any
{
	return [self anyObject];
}


- (id) BX_Collect
{
	return [self BX_CollectReturning: [NSMutableSet class]];
}


- (id) BX_CollectReturning: (Class) aClass
{
	return HOMTrampoline (self, @selector (_BX_Collect:userInfo:), aClass);
}


- (id) BX_CollectD
{
	return HOMTrampoline (self, @selector (_BX_CollectD:userInfo:), nil);
}


- (id) BX_CollectDK
{
	return HOMTrampoline (self, @selector (_BX_CollectDK:userInfo:), nil);
}


- (id) BX_SelectFunction: (int (*)(id)) fptr
{
	id retval = [NSMutableSet setWithCapacity: [self count]];
	return SelectFunction (self, retval, fptr);
}


- (id) BX_SelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg
{
	id retval = [NSMutableSet setWithCapacity: [self count]];
	return SelectFunction2 (self, retval, fptr, arg);
}


- (id) BX_Do
{
	return HOMTrampoline (self, @selector (_BX_Do:userInfo:), nil);
}


- (id) BX_Visit: (id) visitor
{
	return VisitorTrampoline (self, visitor, @selector (_BX_Visit:userInfo:), nil);
}
@end



@implementation NSHashTable (BXHOM)
- (void) _BX_Collect: (NSInvocation *) invocation userInfo: (Class) retclass
{
	id retval = [[[retclass alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerform (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_CollectD: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerformD (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_CollectDK: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerformDK (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_Do: (NSInvocation *) invocation userInfo: (id) anObject
{
	Do (invocation, [self objectEnumerator]);
}


- (void) _BX_Visit: (NSInvocation *) invocation userInfo: (id) userInfo
{
	Visit (invocation, [self objectEnumerator]);
}


- (id) BX_Any
{
	return [self anyObject];
}


- (id) BX_Collect
{
	return [self BX_CollectReturning: [NSMutableSet class]];
}


- (id) BX_CollectReturning: (Class) aClass
{
	return HOMTrampoline (self, @selector (_BX_Collect:userInfo:), aClass);
}


- (id) BX_CollectD
{
	return HOMTrampoline (self, @selector (_BX_CollectD:userInfo:), nil);
}


- (id) BX_CollectDK
{
	return HOMTrampoline (self, @selector (_BX_CollectDK:userInfo:), nil);
}


- (id) BX_SelectFunction: (int (*)(id)) fptr
{
	id retval = [NSMutableSet setWithCapacity: [self count]];
	return SelectFunction (self, retval, fptr);
}


- (id) BX_SelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg
{
	id retval = [NSMutableSet setWithCapacity: [self count]];
	return SelectFunction2 (self, retval, fptr, arg);
}


- (id) BX_Do
{
	return HOMTrampoline (self, @selector (_BX_Do:userInfo:), nil);
}


- (id) BX_Visit: (id) visitor
{
	return VisitorTrampoline (self, visitor, @selector (_BX_Visit:userInfo:), nil);
}
@end



@implementation NSArray (BXHOM)
- (void) _BX_Collect: (NSInvocation *) invocation userInfo: (Class) retclass
{
	id retval = [[[retclass alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerform (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_CollectD: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerformD (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_CollectDK: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerformDK (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_Do: (NSInvocation *) invocation userInfo: (id) userInfo
{
	Do (invocation, [self objectEnumerator]);
}


- (void) _BX_Visit: (NSInvocation *) invocation userInfo: (id) userInfo
{
	Visit (invocation, [self objectEnumerator]);
}


- (NSArray *) BX_Reverse
{
	return [[self reverseObjectEnumerator] allObjects];
}


- (id) BX_Any
{
	return [self lastObject];
}


- (id) BX_Collect
{
	return [self BX_CollectReturning: [NSMutableArray class]];
}


- (id) BX_CollectReturning: (Class) aClass
{
	return HOMTrampoline (self, @selector (_BX_Collect:userInfo:), aClass);
}


- (id) BX_CollectD
{
	return HOMTrampoline (self, @selector (_BX_CollectD:userInfo:), nil);
}


- (id) BX_CollectDK
{
	return HOMTrampoline (self, @selector (_BX_CollectDK:userInfo:), nil);
}


- (id) BX_Do
{
	return HOMTrampoline (self, @selector (_BX_Do:userInfo:), nil);
}


- (id) BX_Visit: (id) visitor
{
	return VisitorTrampoline (self, visitor, @selector (_BX_Visit:userInfo:), nil);
}


- (id) BX_SelectFunction: (int (*)(id)) fptr
{
	id retval = [NSMutableArray arrayWithCapacity: [self count]];
	return SelectFunction (self, retval, fptr);
}


- (id) BX_SelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg
{
	id retval = [NSMutableArray arrayWithCapacity: [self count]];
	return SelectFunction2 (self, retval, fptr, arg);
}
@end



@implementation NSDictionary (BXHOM)
- (void) _BX_Collect: (NSInvocation *) invocation userInfo: (Class) retclass
{
	id retval = [[[retclass alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerform (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_CollectD: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerformD (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_CollectDK: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerformDK (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_KeyCollectD: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	BXEnumerate (currentKey, e, [self keyEnumerator])
	{
		id value = [self objectForKey: currentKey];
		id newKey = nil;
		[invocation invokeWithTarget: currentKey];
		[invocation getReturnValue: &newKey];
		if (newKey)
			[retval setObject: value forKey: newKey];
	}
	retval = [[retval copy] autorelease];
	[invocation setReturnValue: &retval];
}


- (void) _BX_Do: (NSInvocation *) invocation userInfo: (id) userInfo
{
	Do (invocation, [self objectEnumerator]);
}


- (void) _BX_Visit: (NSInvocation *) invocation userInfo: (id) userInfo
{
	Visit (invocation, [self objectEnumerator]);
}


- (id) BX_Any
{
	return [[self objectEnumerator] nextObject];
}


- (id) BX_Collect
{
	return [self BX_CollectReturning: [NSMutableArray class]];
}


- (id) BX_CollectReturning: (Class) aClass
{
	return HOMTrampoline (self, @selector (_BX_Collect:userInfo:), aClass);
}


- (id) BX_CollectD
{
	return HOMTrampoline (self, @selector (_BX_CollectD:userInfo:), nil);
}


- (id) BX_CollectDK
{
	return HOMTrampoline (self, @selector (_BX_CollectDK:userInfo:), nil);
}


- (id) BX_KeyCollectD
{
	return KeyTrampoline (self, @selector (_BX_KeyCollectD:userInfo:), nil);
}


- (id) BX_Do
{
	return HOMTrampoline (self, @selector (_BX_Do:userInfo:), nil);
}


- (id) BX_Visit: (id) visitor
{
	return VisitorTrampoline (self, visitor, @selector (_BX_Visit:userInfo:), nil);
}


- (id) BX_ValueSelectFunction: (int (*)(id)) fptr
{
	id retval = [NSMutableArray arrayWithCapacity: [self count]];
	return SelectFunction (self, retval, fptr);
}


- (id) BX_ValueSelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg
{
	id retval = [NSMutableArray arrayWithCapacity: [self count]];
	return SelectFunction2 (self, retval, fptr, arg);
}
@end



@implementation NSMapTable (BXHOM)
- (void) _BX_Collect: (NSInvocation *) invocation userInfo: (Class) retclass
{
	id retval = [[[retclass alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerform (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_CollectD: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerformD (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_CollectDK: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	CollectAndPerformDK (self, retval, invocation, [self objectEnumerator]);
}


- (void) _BX_KeyCollectD: (NSInvocation *) invocation userInfo: (id) ignored
{
	id retval = [[[NSMutableDictionary alloc] initWithCapacity: [self count]] autorelease];
	BXEnumerate (currentKey, e, [self keyEnumerator])
	{
		id value = [self objectForKey: currentKey];
		id newKey = nil;
		[invocation invokeWithTarget: currentKey];
		[invocation getReturnValue: &newKey];
		if (newKey)
			[retval setObject: value forKey: newKey];
	}
	retval = [[retval copy] autorelease];
	[invocation setReturnValue: &retval];
}


- (void) _BX_Do: (NSInvocation *) invocation userInfo: (id) userInfo
{
	Do (invocation, [self objectEnumerator]);
}


- (void) _BX_Visit: (NSInvocation *) invocation userInfo: (id) userInfo
{
	Visit (invocation, [self objectEnumerator]);
}


- (id) BX_Any
{
	return [[self objectEnumerator] nextObject];
}


- (id) BX_Collect
{
	return [self BX_CollectReturning: [NSMutableArray class]];
}


- (id) BX_CollectReturning: (Class) aClass
{
	return HOMTrampoline (self, @selector (_BX_Collect:userInfo:), aClass);
}


- (id) BX_CollectD
{
	return HOMTrampoline (self, @selector (_BX_CollectD:userInfo:), nil);
}


- (id) BX_CollectDK
{
	return HOMTrampoline (self, @selector (_BX_CollectDK:userInfo:), nil);
}


- (id) BX_KeyCollectD
{
	return KeyTrampoline (self, @selector (_BX_KeyCollectD:userInfo:), nil);
}


- (id) BX_Do
{
	return HOMTrampoline (self, @selector (_BX_Do:userInfo:), nil);
}


- (id) BX_Visit: (id) visitor
{
	return VisitorTrampoline (self, visitor, @selector (_BX_Visit:userInfo:), nil);
}


- (id) BX_ValueSelectFunction: (int (*)(id)) fptr
{
	id retval = [NSMutableArray arrayWithCapacity: [self count]];
	return SelectFunction (self, retval, fptr);
}


- (id) BX_ValueSelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg
{
	id retval = [NSMutableArray arrayWithCapacity: [self count]];
	return SelectFunction2 (self, retval, fptr, arg);
}
@end
