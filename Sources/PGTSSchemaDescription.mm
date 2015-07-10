//
// PGTSSchemaDescription.mm
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

#import "PGTSSchemaDescription.h"
#import "BXHOM.h"
#import "PGTSTableDescription.h"
#import "BXCollectionFunctions.h"
#import "BXLogger.h"


using namespace BaseTen;


@implementation PGTSSchemaDescription
- (void) dealloc
{
	[mTablesByName release];
	[super dealloc];
}


- (PGTSTableDescription *) tableNamed: (NSString *) name
{
	Expect (name);
	return [mTablesByName objectForKey: name];
}


- (NSArray *) allTables
{
	return [mTablesByName allValues];
}


- (void) setTables: (id <NSFastEnumeration>) tables
{
	NSMutableDictionary *tablesByName = [NSMutableDictionary dictionary];
	
	for (PGTSTableDescription *table in tables)
		Insert (tablesByName, [table name], table);
	
	[mTablesByName release];
	mTablesByName = [tablesByName copy];
}
@end
