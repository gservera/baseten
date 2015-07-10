//
// PGTSColumnDescription.m
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

#import "PGTSColumnDescription.h"
#import "NSString+PGTSAdditions.h"
#import "BXLogger.h"


/** 
 * \internal
 * \brief Table field.
 */
@implementation PGTSColumnDescription

- (id) init
{
    if ((self = [super init]))
    {
        mIndex = 0;
    }
    return self;
}


- (void) dealloc
{
	[mDefaultValue release];
	[mType release];
	[super dealloc];
}


- (NSString *) description
{
    return [NSString stringWithFormat: @"<%@ (%p) %@ (%ld)>", 
			[self class], self, mName, (long)mIndex];
}


- (void) setIndex: (NSInteger) anIndex
{
    mIndex = anIndex;
}


- (NSString *) name
{
    return mName;
}


- (NSString *) quotedName: (PGTSConnection *) connection
{
	NSString* retval = nil;
    if (nil != mName)
        retval = [mName quotedIdentifierForPGTSConnection: connection];
    return retval;
}


- (NSInteger) index
{
    return mIndex;
}


- (NSString *) defaultValue
{
	return mDefaultValue;
}


- (PGTSTypeDescription *) type
{
	return mType;
}


- (NSComparisonResult) indexCompare: (PGTSColumnDescription *) aCol
{
    NSComparisonResult result = NSOrderedAscending;
    NSInteger anIndex = aCol->mIndex;
    if (mIndex > anIndex)
        result = NSOrderedDescending;
    else if (mIndex == anIndex)
        result = NSOrderedSame;
    return result;
}


- (BOOL) isNotNull
{
	return mIsNotNull;
}


- (BOOL) isInherited
{
	return mIsInherited;
}


- (void) setType: (PGTSTypeDescription *) type
{
	if (mType != type)
	{
		[mType release];
		mType = [type retain];
	}
}


- (void) setNotNull: (BOOL) aBool
{
	mIsNotNull = aBool;
}


- (void) setInherited: (BOOL) aBool
{
	mIsInherited = aBool;
}


- (void) setDefaultValue: (NSString *) anObject
{
	if (mDefaultValue != anObject)
	{
		[mDefaultValue release];
		mDefaultValue = [anObject retain];
	}
}


- (BOOL) requiresDocuments
{
    SEL s = _cmd;
	BXAssertLog (NO, @"Didn't expect %@ to be called for %@.", NSStringFromSelector(s), self);
	return NO;
}


- (void) setRequiresDocuments: (BOOL) aBool
{
    SEL s = _cmd;
	BXAssertLog (NO, @"Didn't expect %@ to be called for %@.", NSStringFromSelector(s), self);
}
@end



@implementation PGTSXMLColumnDescription
- (BOOL) requiresDocuments
{
	return mRequiresDocuments;
}

- (void) setRequiresDocuments: (BOOL) aBool
{
	mRequiresDocuments = aBool;
}
@end
