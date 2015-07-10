//
// BXPGAdditions.m
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

#import "PGTSAdditions.h"
#import "BXPGAdditions.h"
#import "BXPropertyDescriptionPrivate.h"
#import "BXAttributeDescriptionPrivate.h"
#import "BXDatabaseObjectPrivate.h"
#import "BXPGExpressionVisitor.h"
#import "BXLogger.h"
#import "BXURLEncoding.h"


@implementation NSObject (BXPGAdditions)
- (NSString *) BXPGEscapedName: (PGTSConnection *) connection
{
	return [self PGTSEscapedName: connection];
}
@end


@implementation BXEntityDescription (BXPGInterfaceAdditions)
- (NSString *) BXPGQualifiedName: (PGTSConnection *) connection
{
	NSString* schemaName = [[self schemaName] BXPGEscapedName: connection];
	NSString* name = [[self name] BXPGEscapedName: connection];
    return [NSString stringWithFormat: @"%@.%@", schemaName, name];
}
@end


@implementation BXPropertyDescription (BXPGInterfaceAdditions)
- (void) BXPGVisitKeyPathComponent: (id <BXPGExpressionVisitor>) visitor
{
	[self doesNotRecognizeSelector: _cmd];
}
@end



@implementation BXAttributeDescription (BXPGInterfaceAdditions)
- (NSString *) BXPGQualifiedName: (PGTSConnection *) connection
{    
	return [NSString stringWithFormat: @"%@.%@", 
			[[self entity] BXPGQualifiedName: connection], [[self name] BXPGEscapedName: connection]];
}

- (NSString *) BXPGEscapedName: (PGTSConnection *) connection
{
	return [[self name] BXPGEscapedName: connection];
}

- (void) BXPGVisitKeyPathComponent: (id <BXPGExpressionVisitor>) visitor
{
	[visitor visitAttribute: self];
}
@end


@implementation NSURL (BXPGInterfaceAdditions)
#define SetIf( VALUE, KEY ) if ((VALUE)) [connectionDict setObject: VALUE forKey: KEY];
- (NSMutableDictionary *) BXPGConnectionDictionary
{
	NSMutableDictionary* connectionDict = nil;
	if (0 == [@"pgsql" caseInsensitiveCompare: [self scheme]])
	{
		connectionDict = [NSMutableDictionary dictionary];    
		
		NSString* relativePath = [self relativePath];
		if (1 <= [relativePath length])
			SetIf ([relativePath substringFromIndex: 1], kPGTSDatabaseNameKey);
		
		SetIf ([self host], kPGTSHostKey);
		SetIf ([[self user] BXURLDecodedString], kPGTSUserNameKey);
		SetIf ([[self password] BXURLDecodedString], kPGTSPasswordKey);
		SetIf ([self port], kPGTSPortKey);
	}
	return connectionDict;
}
@end


@implementation BXRelationshipDescription (BXPGInterfaceAdditions)
- (void) BXPGVisitKeyPathComponent: (id <BXPGExpressionVisitor>) visitor
{
	[visitor visitRelationship: self];
}
@end
