//
// BXPGFromItem.m
// BaseTen
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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

#import "BXPGFromItem.h"


@implementation BXPGFromItem
- (void) dealloc
{
	[mAlias release];
	[super dealloc];
}

- (NSString *) alias
{
	return mAlias;
}

- (void) setAlias: (NSString *) aString
{
	if (mAlias != aString)
	{
		[mAlias release];
		mAlias = [aString retain];
	}
}

- (BXEntityDescription *) entity
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}
@end


@implementation BXPGRelationshipFromItem
- (void) dealloc
{
	[mRelationship release];
	[mPrevious release];
	[super dealloc];
}

- (void) setRelationship: (BXRelationshipDescription *) aRel
{
	if (mRelationship != aRel)
	{
		[mRelationship release];
		mRelationship = [aRel retain];
	}
}

- (BXRelationshipDescription *) relationship
{
	return mRelationship;
}

- (BXPGFromItem *) previous
{
	return mPrevious;
}

- (void) setPrevious: (BXPGFromItem *) anItem
{
	if (mPrevious != anItem)
	{
		[mPrevious release];
		mPrevious = [anItem retain];
	}
}

- (BXEntityDescription *) entity
{
	return [mRelationship destinationEntity];
}

- (NSString *) BXPGVisitFromItem: (id <BXPGFromItemVisitor>) visitor
{
	return [visitor visitRelationshipJoinItem: self];
}
@end


@implementation BXPGPrimaryRelationFromItem
- (void) dealloc
{
	[mEntity release];
	[super dealloc];
}

- (BXEntityDescription *) entity
{
	return mEntity;
}

- (void) setEntity: (BXEntityDescription *) anEntity
{
	if (mEntity != anEntity)
	{
		[mEntity release];
		mEntity = [anEntity retain];
	}
}

- (NSString *) BXPGVisitFromItem: (id <BXPGFromItemVisitor>) visitor
{
	return [visitor visitPrimaryRelation: self];
}
@end


@implementation BXPGHelperTableRelationshipFromItem
- (void) dealloc
{
	[mHelperAlias release];
	[super dealloc];
}

- (NSString *) helperAlias
{
	return mHelperAlias;
}

- (void) setHelperAlias: (NSString *) aString
{
	if (mHelperAlias != aString)
	{
		[mHelperAlias release];
		mHelperAlias = [aString retain];
	}
}
@end
