//
// BXPGVisitor.m
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

#import "BXPGVisitor.h"


@implementation BXPGVisitor
- (void) dealloc
{
	[mAliasMapper release];
	[super dealloc];
}

- (void) setRelationAliasMapper: (BXPGRelationAliasMapper *) aMapper
{
	if (mAliasMapper != aMapper)
	{
		[mAliasMapper release];
		mAliasMapper = [aMapper retain];
	}
}

- (BXPGRelationAliasMapper *) relationAliasMapper
{
	return mAliasMapper;
}
@end
