//
// PGTSAbstractDescription.mm
// BaseTen
//
// Copyright 2009-2010 Marko Karppinen & Co. LLC.
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


#import "PGTSAbstractDescription.h"


/** 
 * \internal
 * \brief Abstract base class.
 */
@implementation PGTSAbstractDescription
+ (BOOL) accessInstanceVariablesDirectly
{
    return NO;
}

- (void) dealloc
{
    [mName release];
    [super dealloc];
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"<%@ (%p) %@>", 
			[self class], self, mName];
}

- (NSString *) name
{
	return mName;
}

- (void) setName: (NSString *) aString
{
	if (aString != mName)
	{
		[mName release];
		mName = [aString copy];
		mHash = [mName hash];
	}
}

/**
 * \internal
 * \brief Retain on copy.
 */
- (id) copyWithZone: (NSZone *) zone
{
    return [self retain];
}

- (BOOL) isEqual: (PGTSAbstractDescription *) anObject
{
    BOOL retval = NO;
    if (! [anObject isKindOfClass: [self class]])
        retval = [super isEqual: anObject];
    else
    {
        retval = [mName isEqualToString: anObject->mName];
    }
    return retval;
}

- (NSUInteger) hash
{
    return mHash;
}
@end
