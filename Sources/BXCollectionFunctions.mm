//
// BXCollectionFunctions.mm
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


#import "BXCollectionFunctions.h"
#import "BXLogger.h"


NSValue *
FindElementValue (id collection, id key)
{
	NSValue *retval = nil;
	if (collection)
	{
		Expect ([collection respondsToSelector: @selector (objectForKey:)]);
		retval = [collection objectForKey: key];
		Expect ([retval isKindOfClass: [NSValue class]]);
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
