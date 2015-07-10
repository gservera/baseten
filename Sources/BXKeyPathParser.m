//
// BXKeyPathParser.m
// BaseTen
//
// Copyright 2008-2010 Marko Karppinen & Co. LLC.
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

#import "BXKeyPathParser.h"


#define kStackDepth 16


struct component_retval_st
{
	__strong NSString* cr_component;
	unichar* cr_position;
};


#define Check_Stack_Overflow() if (kStackDepth <= i) [NSException raise: NSInternalInconsistencyException format: @"State stack overflow."]
#define Check_Stack_Unferflow() if (i < 0) [NSException raise: NSInternalInconsistencyException format: @"State stack underflow."]

#define Set_State( STATE ) { i++; Check_Stack_Overflow (); stack [i] = STATE; }
#define Exit_State() { i--; Check_Stack_Unferflow (); }
#define Add_Character( CHARACTER ) { *bufferPtr = CHARACTER; bufferPtr++; }
	

static struct component_retval_st
KeyPathComponent (unichar* stringPtr, unichar* buffer, NSUInteger length)
{
	unichar current = 0;
	unichar stack [kStackDepth] = {};
	short i = 0;
	unichar* bufferPtr = buffer;
	BOOL gotSeparator = NO;
	
	//We accept all characters other than .'"\ in key path components.
	while (0 < length)
	{
		current = *stringPtr;
		switch (stack [i])
		{
			case 0:
			{
				switch (current)
				{
					case '.':
					{
						stringPtr++;
						length--;
						gotSeparator = YES;
						goto end;
						break;
					}
						
					case '"':
					case '\\':
					{
						Set_State (current);
						break;
					}
						
					default:
					{
						Add_Character (current);
						break;
					}
				}				
				break;
			}
			
			case '"':
			{
				switch (current)
				{
					case '"':
					{
						Exit_State ();
						break;
					}
						
					case '\\':
					{
						Set_State (current);
						break;
					}
						
					default:
					{
						Add_Character (current);
						break;
					}
				}
				break;
			}
				
			case '\\':
			{
				switch (current)
				{
					case '\\':
					case '"':
					case '.':
					{
						Add_Character (current);
						Exit_State ();
						break;
					}
						
					default:
					{
						[NSException raise: NSInvalidArgumentException format: @"Invalid character after escape: %d", current];
						break;
					}
				}
			}
				
			default:
			{
				[NSException raise: NSInternalInconsistencyException format: @"Invalid state: %d", stack [i]];
				break;
			}
		}
		
		stringPtr++;
		length--;
	}
	
end:
	if (buffer == bufferPtr || (gotSeparator && ! length))
		[NSException raise: NSInvalidArgumentException format: @"Component with zero length."];
	
	NSString* component = [NSString stringWithCharacters: buffer length: bufferPtr - buffer];
	struct component_retval_st retval = { component, stringPtr };
	return retval;
}


/**
 * \internal
 * \brief A parser for key paths.
 * Accepts some malformed key paths but NSPredicate and other classes probably notice them, when
 * they get re-used.
 * \not This function is thread safe.
 */
NSArray* 
BXKeyPathComponents (NSString* keyPath)
{
	NSMutableArray* retval = [NSMutableArray array];
		
	NSInteger length = [keyPath length];
	unichar* buffer = malloc (length * sizeof (unichar));
	unichar* source = malloc (length * sizeof (unichar));
	unichar* stringPtr = source;
	[keyPath getCharacters: source];
	
	while (0 < length)
	{
		struct component_retval_st cst = KeyPathComponent (stringPtr, buffer, length);
		length -= (cst.cr_position - stringPtr);
		stringPtr = cst.cr_position;
		
		NSString* component = cst.cr_component;
		[retval addObject: component];
	}
	
	if (buffer)
		free (buffer);
	
	if (source)
		free (source);
	
	if (! [retval count])
		retval = nil;
	return [[retval copy] autorelease];
}
