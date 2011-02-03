//
// BXAbstractDescription.m
// BaseTen
//
// Copyright 2008-2009 Marko Karppinen & Co. LLC.
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

#import "BXAbstractDescription.h"
#import "BXLogger.h"


/**
 * \brief An abstract superclass for various description classes.
 *
 * \note This class's documented methods are thread-safe. Creating objects, however, is not.
 * \note For this class to work in non-GC applications, the corresponding database context must be retained as well.
 * \ingroup descriptions
 */
@implementation BXAbstractDescription

- (id) initWithName: (NSString *) aName
{
    if ((self = [super init]))
    {
        BXAssertValueReturn (nil != aName, nil, @"Expected name not to be nil.");
        mName = [aName copy];
		mHash = [mName hash];
    }
    return self;
}

- (id) initWithCoder: (NSCoder *) decoder
{
	if ((self = [self initWithName: [decoder decodeObjectForKey: @"name"]]))
	{
	}
	return self;
}

- (void) dealloc
{
	[mName release];
	[super dealloc];
}

- (void) encodeWithCoder: (NSCoder *) encoder
{
	[encoder encodeObject: mName forKey: @"name"];
}

/** \brief Name of the object. */
- (NSString *) name
{
    return [[mName retain] autorelease];
}

- (NSUInteger) hash
{
    return mHash;
}

- (NSComparisonResult) compare: (id) anObject
{
    NSComparisonResult retval = NSOrderedSame;
    if ([anObject isKindOfClass: [self class]])
        retval = [[self name] compare: [anObject name]];
    return retval;
}

- (NSComparisonResult) caseInsensitiveCompare: (id) anObject
{
    NSComparisonResult retval = NSOrderedSame;
    if ([anObject isKindOfClass: [self class]])
        retval = [[self name] caseInsensitiveCompare: [anObject name]];
    return retval;
}

- (BOOL) isEqual: (BXAbstractDescription *) desc
{
    BOOL retval = NO;
    if ([desc isKindOfClass: [self class]])
    {
        retval = [[self name] isEqualToString: [desc name]];
    }
    return retval;
}
@end
