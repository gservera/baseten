//
// BXCollectionFunctions.mm
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


#import "BXCollectionFunctions.h"
#import "BXLogger.h"


BOOL
FindElement (id collection, id key, void *outValue)
{
	ExpectR (outValue, NO);
	ExpectR ([collection respondsToSelector: @selector (objectForKey:)], NO);

	BOOL retval = NO;
	id value = [collection objectForKey: key];
	if (value)
	{
		ExpectR ([value isKindOfClass: [NSValue class]], NO);
		
		retval = YES;
		[value getValue: outValue];
	}
	
	return retval;
}


template <>
id BaseTen::ObjectValue (float value)
{
	return [NSNumber numberWithFloat: value];
}


template <>
id BaseTen::ObjectValue (double value)
{
	return [NSNumber numberWithDouble: value];
}


template <>
id BaseTen::ObjectValue (char value)
{
	return [NSNumber numberWithChar: value];
}


template <>
id BaseTen::ObjectValue (short value)
{
	return [NSNumber numberWithShort: value];
}	


template <>
id BaseTen::ObjectValue (int value)
{
	return [NSNumber numberWithInt: value];
}


template <>
id BaseTen::ObjectValue (long value)
{
	return [NSNumber numberWithLong: value];
}


template <>
id BaseTen::ObjectValue (long long value)
{
	return [NSNumber numberWithLongLong: value];
}


template <>
id BaseTen::ObjectValue (unsigned char value)
{
	return [NSNumber numberWithUnsignedChar: value];
}


template <>
id BaseTen::ObjectValue (unsigned short value)
{
	return [NSNumber numberWithUnsignedShort: value];
}	


template <>
id BaseTen::ObjectValue (unsigned int value)
{
	return [NSNumber numberWithUnsignedInt: value];
}


template <>
id BaseTen::ObjectValue (unsigned long value)
{
	return [NSNumber numberWithUnsignedLong: value];
}


template <>
id BaseTen::ObjectValue (unsigned long long value)
{
	return [NSNumber numberWithUnsignedLongLong: value];
}
