//
// PGTSSchemaObjectDescription.m
// BaseTen
//
// Copyright 2009 Marko Karppinen & Co. LLC.
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

#import "PGTSSchemaObjectDescription.h"


/** 
 * \internal
 * \brief Abstract base class for database objects that have a schema.
 */
@implementation PGTSSchemaObjectDescription
- (void) dealloc
{
	[mOwner release];
	[super dealloc];
}

- (PGTSSchemaDescription *) schema
{
	return mSchema;
}

- (PGTSRoleDescription *) owner
{
	return mOwner;
}

- (void) setSchema: (PGTSSchemaDescription *) aSchema
{
	mSchema = aSchema;
}

- (void) setOwner: (PGTSRoleDescription *) aRole
{
	if (mOwner != aRole)
	{
		[mOwner release];
		mOwner = [aRole retain];
	}
}
@end
