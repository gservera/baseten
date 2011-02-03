//
// BXPGForeignKeyDescription.mm
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
