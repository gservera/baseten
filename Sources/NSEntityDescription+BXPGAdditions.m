//
// NSEntityDescription+BXPGAdditions.m
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

#import "NSEntityDescription+BXPGAdditions.h"
#import "NSAttributeDescription+BXPGAdditions.h"
#import "BXLogger.h"
#import "BXEnumerate.h"
#import "PGTSOids.h"


@implementation NSEntityDescription (BXPGAdditions)
- (NSString *) BXPGCreateStatementWithIDColumn: (BOOL) addSerialIDColumn 
									  inSchema: (NSString *) schemaName
									connection: (PGTSConnection *) connection
										errors: (NSMutableArray *) errors
{
	Expect (schemaName);

	NSString* name = [self name];
	NSEntityDescription* superentity = [self superentity];
	//-attributesByName would return only attribute descriptions, but we need an ordered collection.
    //FIXED: Sorting
	NSArray* properties = [[self properties] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    NSMutableArray* attributeDefs = [NSMutableArray arrayWithCapacity: 1 + [properties count]];
    if (YES == addSerialIDColumn)
        [attributeDefs addObject: @"id SERIAL"];

	BXEnumerate (currentProperty, e, [properties objectEnumerator])
	{
		if (! [currentProperty isKindOfClass: [NSAttributeDescription class]])
			continue;
		
		//Transient values are not stored
		if ([currentProperty isTransient])
			continue;
		
		//Superentities' attributes won't be repeated here.
        //FIX: OLD CODE DIDN'T SEEM TO WORK, ENTITY ON PROPERTY IS SET TO SELF INSTEAD OF SUPER
		if ([superentity propertiesByName][[currentProperty name]] != nil)
			continue;
		
		NSError* attrError = nil;
		if (! [currentProperty BXCanAddAttribute: &attrError])
			[errors addObject: attrError];
		else
		{
			NSString* attrDef = [currentProperty BXPGAttributeDefinition: connection];
			[attributeDefs addObject: attrDef];
		}
	}
	
	NSString* addition = @"";
	if (superentity)
		addition = [NSString stringWithFormat: @"INHERITS (\"%@\".\"%@\")", schemaName, [superentity name]];
	
	NSString* statementFormat = @"CREATE TABLE \"%@\".\"%@\" (%@) %@;";
	NSString* retval = [NSString stringWithFormat: statementFormat, schemaName, name,
						[attributeDefs componentsJoinedByString: @", "], addition];
	
	return retval;
}

- (NSString *) BXPGPrimaryKeyConstraintInSchema: (NSString *) schemaName
{
	NSString* format = @"ALTER TABLE \"%@\".\"%@\" ADD PRIMARY KEY (id);";
	NSString* constraint = [NSString stringWithFormat: format, schemaName, [self name]];
	return constraint;
}
@end
