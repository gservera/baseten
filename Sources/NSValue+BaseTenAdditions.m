//
// NSValue+BaseTenAdditions.m
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
