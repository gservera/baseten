//
// NSNumber+BaseTenAdditions.mm
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

#import "NSNumber+BaseTenAdditions.h"
#import "NSValue+BaseTenAdditions.h"
#import "BXLogger.h"


@implementation NSNumber (BaseTenAdditions)
- (size_t) BXValueSize
{
	return CFNumberGetByteSize ((CFNumberRef) self);
}


- (BOOL) BXGetValue: (void *) buffer 
			 length: (size_t) bufferLength
		 numberType: (CFNumberType) expectedNumberType 
		   encoding: (const char *) expectedEncoding
{
	BOOL retval = NO;
	
	if (expectedNumberType)
		retval = CFNumberGetValue ((CFNumberRef) self, expectedNumberType, buffer);
	else
		retval = [super BXGetValue: buffer length: bufferLength numberType: expectedNumberType encoding: expectedEncoding];
	
	return retval;
}
@end



@implementation NSNumber (BXExpressionValue)
- (enum BXExpressionValueType) getBXExpressionValue: (id *) outValue usingContext: (NSMutableDictionary *) context;
{
	ExpectR (outValue, kBXExpressionValueTypeUndefined);
	
	if (0 == strcmp ("c", [self objCType]))
		*outValue = ([self boolValue] ? @"true" : @"false");
	else
		*outValue = self;
	
	return kBXExpressionValueTypeConstant;
}
@end
