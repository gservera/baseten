//
// BXPGDatabaseDescription.m
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

#import "BXPGDatabaseDescription.h"
#import "BXLogger.h"
#import "PGTSConnection.h"
#import "PGTSResultSet.h"
#import "BXPGTableDescription.h"
#import "BXPGForeignKeyDescription.h"
#import "BXCollectionFunctions.h"


using namespace BaseTen;


@implementation BXPGDatabaseDescription
- (void) dealloc
{
	[mSchemaVersion release];
	[mSchemaCompatibilityVersion release];
	[mForeignKeysByIdentifier release];
	[super dealloc];
}

- (BOOL) hasBaseTenSchema
{
	return mHasBaseTenSchema;
}


- (BOOL) hasCompatibleBaseTenSchemaVersion
{
	return mHasCompatibleBaseTenSchemaVersion;
}


- (NSNumber *) schemaVersion
{
	return mSchemaVersion;
}

- (NSNumber *) schemaCompatibilityVersion
{
	return mSchemaCompatibilityVersion;
}

- (void) setSchemaVersion: (NSNumber *) number
{
	if (mSchemaVersion != number)
	{
		[mSchemaVersion release];
		mSchemaVersion = [number retain];
	}
}

- (void) setSchemaCompatibilityVersion: (NSNumber *) number
{
	if (mSchemaCompatibilityVersion != number)
	{
		[mSchemaCompatibilityVersion release];
		mSchemaCompatibilityVersion = [number retain];
	}
}

- (void) setHasBaseTenSchema: (BOOL) aBool
{
	mHasBaseTenSchema = aBool;
}


- (void) setHasCompatibleBaseTenSchemaVersion: (BOOL) flag
{
	mHasCompatibleBaseTenSchemaVersion = flag;
}


- (void) setForeignKeys: (id <NSFastEnumeration>) foreignKeys
{
	NSMutableDictionary *foreignKeysByIdentifier = [NSMutableDictionary dictionary];
	for (BXPGForeignKeyDescription *fkey in foreignKeys)
		Insert (foreignKeysByIdentifier, [fkey identifier], fkey);
	
	[mForeignKeysByIdentifier release];
	mForeignKeysByIdentifier = [foreignKeysByIdentifier copy];
}


- (BXPGForeignKeyDescription *) foreignKeyWithIdentifier: (NSInteger) identifier
{
	return FindObject (mForeignKeysByIdentifier, identifier);
}
@end
