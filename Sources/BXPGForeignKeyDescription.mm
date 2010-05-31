//
// BXPGForeignKeyDescription.mm
// BaseTen
//
// Copyright (C) 2006-2009 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://basetenframework.org/licensing/ or by contacting
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


#import "BXPGForeignKeyDescription.h"
#import "BXLogger.h"
#import "BXCollectionFunctions.h"


@interface BXPGForeignKeyDescriptionKeyPair : NSObject
{
	NSString *mSrcKey;
	NSString *mDstKey;
}
- (NSString *) srcKey;
- (NSString *) dstKey;
- (void) setSrcKey: (NSString *) key;
- (void) setDstKey: (NSString *) key;
@end



@implementation BXPGForeignKeyDescriptionKeyPair
- (void) dealloc
{
	[mSrcKey release];
	[mDstKey release];
	[super dealloc];
}


- (NSString *) srcKey
{
	return [[mSrcKey retain] autorelease];
}


- (NSString *) dstKey
{
	return [[mDstKey retain] autorelease];
}


- (void) setSrcKey: (NSString *) srcKey
{
	if (mSrcKey != srcKey)
	{
		[mSrcKey release];
		mSrcKey = [srcKey retain];
	}
}


- (void) setDstKey: (NSString *) dstKey
{
	if (mDstKey != dstKey)
	{
		[mDstKey release];
		mDstKey = [dstKey retain];
	}
}
@end



@implementation BXPGForeignKeyDescription
- (void) dealloc
{
	[mFieldNames release];
	[super dealloc];
}


- (void) setSrcFieldNames: (NSArray *) srcFields dstFieldNames: (NSArray *) dstFields
{
	NSUInteger count = [srcFields count];
	ExpectV ([dstFields count] == count);
	
	NSMutableArray *keyPairs = [NSMutableArray arrayWithCapacity: count];
	for (NSUInteger i = 0; i < count; i++)
	{
		BXPGForeignKeyDescriptionKeyPair *pair = [[BXPGForeignKeyDescriptionKeyPair alloc] init];
		[pair setSrcKey: [srcFields objectAtIndex: i]];
		[pair setDstKey: [dstFields objectAtIndex: i]];
		[keyPairs addObject: pair];
		[pair release];
	}
	
	[mFieldNames release];
	mFieldNames = [keyPairs copy];
}


- (NSDeleteRule) deleteRule
{
	return mDeleteRule;
}

- (void) setDeleteRule: (NSDeleteRule) aRule
{
	mDeleteRule = aRule;
}

- (NSInteger) identifier
{
	return mIdentifier;
}

- (void) setIdentifier: (NSInteger) identifier
{
	mIdentifier = identifier;
}

- (void) iterateColumnNames: (void (*)(NSString* srcName, NSString* dstName, void* context)) callback context: (void *) context
{
	for (BXPGForeignKeyDescriptionKeyPair *pair in mFieldNames)
		callback ([pair srcKey], [pair dstKey], context);
}

- (void) iterateReversedColumnNames: (void (*)(NSString* dstName, NSString* srcName, void* context)) callback context: (void *) context
{
	for (BXPGForeignKeyDescriptionKeyPair *pair in mFieldNames)
		callback ([pair dstKey], [pair srcKey], context);
}

- (NSUInteger) numberOfColumns
{
	return [mFieldNames count];
}
@end
