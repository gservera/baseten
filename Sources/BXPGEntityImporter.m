//
// BXPGEntityImporter.m
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

#import "BXPGEntityImporter.h"
#import "BXLogger.h"
#import "BXPGInterface.h"
#import "BXDatabaseContextPrivate.h"
#import "BXPGTransactionHandler.h"
#import "BXPGEntityConverter.h"
#import "PGTSResultSet.h"
#import "BXHOM.h"
#import "PGTSDatabaseDescription.h"



@interface BXPGEntityImporter ()
- (void) receivedResult: (PGTSResultSet *) res;
@end



@implementation BXPGEntityImporter
- (void) dealloc
{
	[mContext release];
	[mEntityConverter setDelegate: nil];
	[mEntityConverter release];
	[mEntities release];
	[mSchemaName release];
	[mStatements release];
	[mEnabledRelations release];
	[super dealloc];
}


- (void) setDatabaseContext: (BXDatabaseContext *) aContext
{
	if (mContext != aContext)
	{
		[mContext release];
		mContext = [aContext retain];
	}
}


- (void) setConverter: (BXPGEntityConverter *) aConverter
{
	if (mEntityConverter != aConverter)
	{
		[mEntityConverter setDelegate: nil];
		[mEntityConverter release];
		
		mEntityConverter = [aConverter retain];
		[mEntityConverter setDelegate: self];
	}
}


- (void) setStatements: (NSArray *) anArray
{
	if (mStatements != anArray)
	{
		[mStatements release];
		mStatements = [anArray retain];
	}
}


- (void) setEntities: (NSArray *) aCollection
{
	if (mEntities != aCollection)
	{
		[mEntities release];
		mEntities = [aCollection retain];
		
		[self setStatements: nil];
	}
}


- (void) setSchemaName: (NSString *) aName
{
	if (mSchemaName != aName)
	{
		[mSchemaName release];
		mSchemaName = [aName retain];
	}
}


- (void) setEnabledRelations: (NSArray *) anArray
{
	if (mEnabledRelations != anArray)
	{
		[mEnabledRelations release];
		mEnabledRelations = [anArray retain];
	}
}


- (void) setDelegate: (id <BXPGEntityImporterDelegate>) anObject
{
	mDelegate = anObject;
}


- (NSArray *) importStatements
{
	return [self importStatements: NULL];
}


- (NSArray *) importStatements: (NSArray **) outErrors
{
	Expect (mContext);
	Expect (mEntities);
	
	if (! [mSchemaName length])
		[self setSchemaName: @"public"];

	if (! mEntityConverter)
	{
		mEntityConverter = [[BXPGEntityConverter alloc] init];
		[mEntityConverter setDelegate: self];
	}
	
	NSArray* enabledRelations = nil;
	NSArray* statements = [mEntityConverter statementsForEntities: mEntities 
													   schemaName: mSchemaName
												 enabledRelations: &enabledRelations
														   errors: outErrors];
	[self setStatements: statements];
	[self setEnabledRelations: enabledRelations];
	return statements;
}


- (void) enumerateStatements: (NSEnumerator *) statementEnumerator
{
	NSString* statement = [statementEnumerator nextObject];
	if (statement)
	{
		[mDelegate entityImporterAdvanced: self];
		
		PGTSConnection* connection = [[(BXPGInterface *) [mContext databaseInterface] transactionHandler] connection];
		[connection sendQuery: statement delegate: self callback: @selector (receivedResult:) 
			   parameterArray: nil userInfo: statementEnumerator];
	}
	else
	{
		[mDelegate entityImporter: self finishedImporting: YES error: nil];
	}
}


- (void) receivedResult: (PGTSResultSet *) res
{
	if ([res querySucceeded])
		[self enumerateStatements: [res userInfo]];
	else
		[mDelegate entityImporter: self finishedImporting: NO error: [res error]];
}


- (void) importEntities
{
	NSArray* statements = [self importStatements];
	[self enumerateStatements: [statements objectEnumerator]];
}


- (BOOL) enableEntities: (NSError **) outError
{
	BOOL retval = YES;
	
	ExpectR (mSchemaName, NO);
	if (0 < [mEnabledRelations count])
	{
		NSString* queryString = 
		@"SELECT baseten.enable (c.oid) "
		"  FROM pg_class c, pg_namespace n "
		"  WHERE c.relnamespace = n.oid AND n.nspname = $1 AND c.relname = ANY ($2);";
		
		PGTSConnection* connection = [[(BXPGInterface *) [mContext databaseInterface] transactionHandler] connection];
		PGTSResultSet* res = [connection executeQuery: queryString parameters: mSchemaName, mEnabledRelations];
		
		if (! [res querySucceeded])
		{
			retval = NO;
			if (outError)
				*outError = [res error];
		}
	}
	return retval;
}


- (BOOL) disableEntities: (NSArray *) entities error: (NSError **) outError
{
	BOOL retval = YES;
	ExpectR (mSchemaName, NO);
	if (0 < [entities count])
	{
		NSArray* names = (id) [[entities BX_Collect] name];
		NSString* queryString = 
		@"SELECT baseten.disable (c.oid) "
		"  FROM pg_class c, pg_namespace n "
		"  WHERE c.relnamespace = n.oid AND n.nspname = $1 AND c.relname = ANY ($2);";
		
		PGTSConnection* connection = [[(BXPGInterface *) [mContext databaseInterface] transactionHandler] connection];
		PGTSResultSet* res = [connection executeQuery: queryString parameters: mSchemaName, names];
		
		if (! [res querySucceeded])
		{
			retval = NO;
			if (outError)
				*outError = [res error];
		}
	}
	return retval;
}
@end



@implementation BXPGEntityImporter (BXPGEntityConverterDelegate)
- (BXEntityDescription *) entityConverter: (BXPGEntityConverter *) converter 
 shouldAddDropStatementFromEntityMatching: (NSEntityDescription *) importedEntity
								 inSchema: (NSString *) schemaName
									error: (NSError **) outError
{
	BXEntityDescription *retval = [[mContext databaseObjectModel] matchingEntity: importedEntity inSchema: schemaName];
	ExpectL (! retval || [retval isValidated]);
	return retval;
}


- (BOOL) entityConverter: (BXPGEntityConverter *) converter shouldCreateSchema: (NSString *) schemaName
{
	ExpectR (mContext, NO);
	PGTSConnection* connection = [[(BXPGInterface *) [mContext databaseInterface] transactionHandler] connection];
	PGTSDatabaseDescription* database = [connection databaseDescription];
	return ([database schemaNamed: schemaName] ? NO : YES);
}


- (PGTSConnection *) connectionForEntityConverter: (BXPGEntityConverter *) converter
{
	Expect (mContext);
	return [[(BXPGInterface *) [mContext databaseInterface] transactionHandler] connection];
}
@end
