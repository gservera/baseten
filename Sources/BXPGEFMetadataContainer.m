//
// BXPGEFMetadataContainer.m
// BaseTen
//
// Copyright (C) 2009 Marko Karppinen & Co. LLC.
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

#import "BXPGEFMetadataContainer.h"
#import "BXPGDatabaseDescription.h"
#import "BXPGTableDescription.h"
#import "PGTSIndexDescription.h"
#import "PGTSConnection.h"
#import "PGTSResultSet.h"
#import "BXLogger.h"
#import "BXEnumerate.h"
#import "BXPGInterface.h"
#import "BXPGForeignKeyDescription.h"
#import "PGTSDeleteRule.h"


@implementation BXPGEFMetadataContainer
- (Class) databaseDescriptionClass
{
	return [BXPGDatabaseDescription class];
}


- (Class) tableDescriptionClass
{
	return [BXPGTableDescription class];
}


- (void) fetchSchemaVersion: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	NSString* query =
	@"SELECT baseten.version () AS version "
	@" UNION ALL "
	@" SELECT baseten.compatibilityversion () AS version";
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded]);
	
	[res advanceRow];
	[mDatabase setSchemaVersion: [res valueForKey: @"version"]];
	[res advanceRow];
	[mDatabase setSchemaCompatibilityVersion: [res valueForKey: @"version"]];	
}


- (void) fetchPreparedRelations: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	NSString* query = @"SELECT oid FROM baseten.relation_oids WHERE enabled = true";
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded]);
	
	while ([res advanceRow])
	{
		Oid oid = [[res valueForKey: @"oid"] PGTSOidValue];
		id table = [loadState tableWithOid: oid];
		[table setEnabled: YES];
	}	
}


- (void) fetchViewPrimaryKeys: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	NSString* query = @"SELECT oid, attnames FROM baseten.view_pkey_oids";
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded]);
	
	{
		while ([res advanceRow])
		{
			Oid oid = [[res valueForKey: @"oid"] PGTSOidValue];
			PGTSTableDescription *view = [loadState tableWithOid: oid];
			PGTSIndexDescription *index = [loadState addIndexForRelation: oid];
			ExpectV (view);
			ExpectV (index);
			
			NSDictionary* columns = [view columns];
			NSMutableSet* indexFields = [NSMutableSet set];
			BXEnumerate (currentCol, e, [[res valueForKey: @"attnames"] objectEnumerator])
				[indexFields addObject: [columns objectForKey: currentCol]];
			
			[index setPrimaryKey: YES];
			[index setColumns: indexFields];
		}
	}
}


- (void) fetchForeignKeys: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	NSString* query = 
	@"SELECT conid, conname, conkey, confkey, confdeltype "
	@" FROM baseten.foreign_key ";
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded]);
	
	NSMutableArray *foreignKeys = [NSMutableArray arrayWithCapacity: [res count]];
	while ([res advanceRow])
	{
		BXPGForeignKeyDescription* fkey = [[[BXPGForeignKeyDescription alloc] init] autorelease];
		[fkey setIdentifier: [[res valueForKey: @"conid"] integerValue]];
		[fkey setName: [res valueForKey: @"conname"]];
		
		NSArray* srcfnames = [res valueForKey: @"conkey"];
		NSArray* dstfnames = [res valueForKey: @"confkey"];
		[fkey setSrcFieldNames: srcfnames dstFieldNames: dstfnames];
		
		NSDeleteRule deleteRule = NSDenyDeleteRule;
		enum PGTSDeleteRule pgDeleteRule = PGTSDeleteRule ([[res valueForKey: @"confdeltype"] characterAtIndex: 0]);
		switch (pgDeleteRule)
		{
			case kPGTSDeleteRuleUnknown:
			case kPGTSDeleteRuleNone:
			case kPGTSDeleteRuleNoAction:
			case kPGTSDeleteRuleRestrict:
				deleteRule = NSDenyDeleteRule;
				break;
				
			case kPGTSDeleteRuleCascade:
				deleteRule = NSCascadeDeleteRule;
				break;
				
			case kPGTSDeleteRuleSetNull:
			case kPGTSDeleteRuleSetDefault:
				deleteRule = NSNullifyDeleteRule;
				break;
				
			default:
				break;
		}
		[fkey setDeleteRule: deleteRule];
		
		[foreignKeys addObject: fkey];
	}
	[mDatabase setForeignKeys: foreignKeys];
}


- (void) fetchBXSpecific: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	NSString* query = @"SELECT EXISTS (SELECT n.oid FROM pg_namespace n WHERE nspname = 'baseten') AS exists";
	PGTSResultSet* res = [connection executeQuery: query];
	ExpectV ([res querySucceeded])
	
	[res advanceRow];
	BOOL hasSchema = [[res valueForKey: @"exists"] boolValue];
	[mDatabase setHasBaseTenSchema: hasSchema];
	
	if (hasSchema)
	{
		[self fetchSchemaVersion: connection loadState: loadState];
		
		NSNumber* currentCompatVersion = [BXPGVersion currentCompatibilityVersionNumber];
		if ([currentCompatVersion isEqualToNumber: [mDatabase schemaCompatibilityVersion]])
		{
			[mDatabase setHasCompatibleBaseTenSchemaVersion: YES];
			[self fetchPreparedRelations: connection loadState: loadState];
			[self fetchViewPrimaryKeys: connection loadState: loadState];
			[self fetchForeignKeys: connection loadState: loadState];
		}
		else
		{
			BXLogInfo (@"BaseTen schema is installed but its compatibility version is %@ while the framework's is %@.", 
					   [mDatabase schemaCompatibilityVersion], currentCompatVersion);
		}
	}
}


- (void) loadUsing: (PGTSConnection *) connection loadState: (PGTSMetadataContainerLoadState *) loadState
{
	[super loadUsing: connection loadState: loadState];
	[self fetchBXSpecific: connection loadState: loadState];
}
@end
