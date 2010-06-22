//
// NSValue+BaseTenAdditions.m
// BaseTen
//
// Copyright (C) 2010 Marko Karppinen & Co. LLC.
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

#import "NSValue+BaseTenAdditions.h"
#import "BXLogger.h"


static size_t
ValueSize (NSValue *value)
{
	size_t retval = SIZE_T_MAX;
	char const * const encoding = [value objCType];
	ExpectR (encoding, retval);
	
	switch (encoding [0])
	{
		case 'c':
			retval = sizeof (signed char);
			break;
			
		case 'i':
			retval = sizeof (signed int);
			break;
			
		case 's':
			retval = sizeof (signed short);
			break;
			
		case 'l':
			retval = sizeof (signed long);
			break;
			
		case 'q':
			retval = sizeof (signed long long);
			break;
			
		case 'C':
			retval = sizeof (unsigned char);
			break;
			
		case 'I':
			retval = sizeof (unsigned int);
			break;
			
		case 'S':
			retval = sizeof (unsigned short);
			break;
			
		case 'L':
			retval = sizeof (unsigned long);
			break;
			
		case 'Q':
			retval = sizeof (unsigned long long);
			break;
			
		case 'f':
			retval = sizeof (float);
			break;
			
		case 'd':
			retval = sizeof (double);
			break;
			
		case 'B':
			retval = sizeof (_Bool);
			break;
			
		case '*':
			retval = sizeof (char *);
			break;
			
		case '@':
			retval = sizeof (id);
			break;
			
		case '#':
			retval = sizeof (Class);
			break;
			
		case ':':
			retval = sizeof (SEL);
			break;
			
		case '^':
			retval = sizeof (void *);
			break;
			
		default:
			BXLogError (@"Unable to calculate size for type encoding '%s'.", encoding);
			break;
	}
	
	return retval;
}



@implementation NSValue (BaseTenAdditions)
- (size_t) BXValueSize
{
	return ValueSize (self);
}


- (BOOL) BXGetValue: (void *) buffer 
			 length: (size_t) bufferLength
		 numberType: (CFNumberType) expectedNumberType 
		   encoding: (const char *) expectedEncoding
{
	BOOL retval = NO;
	if (0 == strcmp (expectedEncoding, [self objCType]))
	{
		retval = YES;
		[self getValue: &buffer];
	}
	return retval;
}
@end
