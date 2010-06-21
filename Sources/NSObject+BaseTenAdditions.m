//
// NSObject+BaseTenAdditions.m
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


@implementation NSPointerArray (BaseTenAdditions)
- (void) addObject: (id) anObject
{
	[self addPointer: anObject];
}


- (NSEnumerator *) objectEnumerator
{
	return [[self allObjects] objectEnumerator];
}
@end



@implementation NSMapTable (BaseTenAdditions)
- (void) makeObjectsPerformSelector: (SEL) selector withObject: (id) object
{
	NSEnumerator *e = [self objectEnumerator];
	id currentObject = nil;
	while ((currentObject = [e nextObject]))
		[currentObject performSelector: selector withObject: object];
}


- (NSArray *) objectsForKeys: (NSArray *) keys notFoundMarker: (id) marker
{
	NSMutableArray *retval = [NSMutableArray arrayWithCapacity: [keys count]];
	NSEnumerator *e = [keys objectEnumerator];
	id currentKey = nil;
	while ((currentKey = [e nextObject]))
	{
		id object = [self objectForKey: currentKey];
		if (! object)
			object = marker;
		[retval addObject: object];
	}
	return retval;
}
@end
