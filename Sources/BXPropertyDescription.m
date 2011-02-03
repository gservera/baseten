//
// BXPropertyDescription.m
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

#import "BXPropertyDescription.h"
#import "BXPropertyDescriptionPrivate.h"
#import "BXEntityDescription.h"
#import "BXLogger.h"


/**
 * \brief A superclass for various description classes.
 * \note This class's documented methods are thread-safe. Creating objects, however, is not.
 * \note For this class to work in non-GC applications, the corresponding database context must be retained as well.
 * \ingroup descriptions
 */
@implementation BXPropertyDescription

/** \brief Entity for this property. */
- (BXEntityDescription *) entity
{
    return mEntity;
}

/** \brief Retain on copy. */
- (id) copyWithZone: (NSZone *) zone
{
    return [self retain];
}

//FIXME: need we this?
#if 0
- (id) mutableCopyWithZone: (NSZone *) zone
{
	id retval = [[[self class] allocWithZone: zone] initWithName: mName entity: mEntity];
	//Probably best not to set flags?
	return retval;
}
#endif

- (id) initWithCoder: (NSCoder *) decoder
{
	if ((self = [super initWithCoder: decoder]))
	{
		mEntity = [decoder decodeObjectForKey: @"entity"];
		[self setOptional: [decoder decodeBoolForKey: @"isOptional"]];
	}
	return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
	[coder encodeObject: mEntity forKey: @"entity"];	
	[coder encodeBool: [self isOptional] forKey: @"isOptional"];
	[super encodeWithCoder: coder];
}

- (NSUInteger) hash
{
	return mHash;
}

- (BOOL) isEqual: (id) anObject
{
	BOOL retval = NO;
	if (anObject == self)
		retval = YES;
	else if ([super isEqual: anObject] && [anObject isKindOfClass: [self class]])
	{
		BXPropertyDescription* aDesc = (BXPropertyDescription *) anObject;
		retval = [mEntity isEqual: aDesc->mEntity];
	}
    return retval;
}

- (NSString *) description
{
    //return [NSString stringWithFormat: @"<%@ (%p) name: %@ entity: %@>", [self class], self, name, mEntity];
	return [self qualifiedName];
}

- (NSComparisonResult) caseInsensitiveCompare: (BXPropertyDescription *) anotherObject
{
    NSComparisonResult retval = NSOrderedSame;
    if (self != anotherObject)
    {
        retval = [[self entity] caseInsensitiveCompare: [anotherObject entity]];
        if (NSOrderedSame == retval)
            retval = [[self name] caseInsensitiveCompare: [anotherObject name]];
    }
    return retval;
}

/** \brief Whether the property is optional. */
- (BOOL) isOptional
{
	return (mFlags & kBXPropertyOptional ? YES : NO);
}

/** \brief The property's subtype. */
- (enum BXPropertyKind) propertyKind
{
	return kBXPropertyNoKind;
}
@end


@implementation BXPropertyDescription (PrivateMethods)
- (void) setOptional: (BOOL) optional
{
	if (optional)
		mFlags |= kBXPropertyOptional;
	else
		mFlags &= ~kBXPropertyOptional;	
}

/**
 * \internal
 * \brief The designated initializer.
 */
- (id) initWithName: (NSString *) aName entity: (BXEntityDescription *) anEntity
{
    if ((self = [super initWithName: aName]))
    {
		mEntity = anEntity;
		mHash = [super hash] ^ [mEntity hash];
	}
	return self;
}

- (id) initWithName: (NSString *) name
{
	[self doesNotRecognizeSelector: _cmd];
    return nil;
}

- (NSString *) qualifiedName
{
	return [NSString stringWithFormat: @"%@.%@.%@", [mEntity schemaName], [mEntity name], mName];
}
@end
