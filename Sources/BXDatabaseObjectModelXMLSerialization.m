//
// BXDatabaseObjectModelXMLSerialization.m
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

#import "BXDatabaseObjectModelXMLSerialization.h"
#import "BXDatabaseObjectModel.h"
#import "BXEnumerate.h"
#import "BXEntityDescription.h"
#import "BXAttributeDescription.h"
#import "BXRelationshipDescription.h"
#import "BXRelationshipDescriptionPrivate.h"


@implementation BXDatabaseObjectModelXMLSerialization
+ (NSData *) dataFromObjectModel: (BXDatabaseObjectModel *) objectModel 
						 options: (enum BXDatabaseObjectModelSerializationOptions) options
						   error: (NSError **) outError
{
	return [[self documentFromObjectModel: objectModel options: options error: outError] XMLData];
}


+ (NSXMLDocument *) documentFromObjectModel: (BXDatabaseObjectModel *) objectModel 
									options: (enum BXDatabaseObjectModelSerializationOptions) options
									  error: (NSError **) outError
{
	const BOOL exportFkeyRelationships    = options & kBXDatabaseObjectModelSerializationOptionRelationshipsUsingFkeyNames;
	const BOOL exportRelNameRelationships = options & kBXDatabaseObjectModelSerializationOptionRelationshipsUsingTargetRelationNames;
	
	if (options & kBXDatabaseObjectModelSerializationOptionExcludeForeignKeyAttributes)
		BXLogWarning (@"kBXDatabaseObjectModelSerializationOptionExcludeForeignKeyAttributes is ignored for %@", self);
	if (options & kBXDatabaseObjectModelSerializationOptionCreateRelationshipsAsOptional)
		BXLogWarning (@"kBXDatabaseObjectModelSerializationOptionCreateRelationshipsAsOptional is ignored for %@", self);

	NSXMLElement* root = [NSXMLElement elementWithName: @"objectModel"];
	NSXMLDocument* retval = [NSXMLDocument documentWithRootElement: root];
	
	NSArray* entities = [[objectModel entities] sortedArrayUsingSelector: @selector (compare:)];
	BXEnumerate (currentEntity, e, [entities objectEnumerator])
	{
		NSXMLElement* entity = [NSXMLElement elementWithName: @"entity"];
		NSXMLElement* elID = [NSXMLElement attributeWithName: @"id" stringValue:
							  [NSString stringWithFormat: @"%@__%@", [currentEntity schemaName], [currentEntity name]]];
		[entity addAttribute: elID];
		NSXMLElement* isView = [NSXMLElement attributeWithName: @"isView" stringValue: ([currentEntity isView] ? @"true" : @"false")];
		[entity addAttribute: isView];

		NSXMLElement* schemaName = [NSXMLElement elementWithName: @"schemaName" stringValue: [currentEntity schemaName]];
		NSXMLElement* name = [NSXMLElement elementWithName: @"name" stringValue: [currentEntity name]];
		[entity addChild: schemaName];
		[entity addChild: name];
		
		NSXMLElement* attrs = [NSXMLElement elementWithName: @"attributes"];
		NSArray *attrDescs = [[[currentEntity attributesByName] allValues] sortedArrayUsingSelector: @selector (compare:)];
		BXEnumerate (currentAttr, e, [attrDescs objectEnumerator])
		{
			if (! [currentAttr isExcluded])
			{
				NSXMLElement* attr = [NSXMLElement elementWithName: @"attribute"];
				NSXMLElement* name = [NSXMLElement elementWithName: @"name" stringValue: [currentAttr name]];
				NSXMLElement* type = [NSXMLElement elementWithName: @"type" stringValue: [currentAttr databaseTypeName]];
				[attr addChild: name];
				[attr addChild: type];
				
				NSXMLElement* isInherited = [NSXMLElement attributeWithName: @"isInherited" stringValue: ([currentAttr isInherited] ? @"true" : @"false")];
				[attr addAttribute: isInherited];
				
				[attrs addChild: attr];
			}
		}
		[entity addChild: attrs];
		
		if ((exportFkeyRelationships || exportRelNameRelationships) && [currentEntity hasCapability: kBXEntityCapabilityRelationships])
		{
			NSXMLElement* rels = [NSXMLElement elementWithName: @"relationships"];
			NSArray *relDescs = [[[currentEntity relationshipsByName] allValues] sortedArrayUsingSelector: @selector (compare:)];
			BXEnumerate (currentRel, e, [relDescs objectEnumerator])
			{
				BOOL usesRelNames = [currentRel usesRelationNames];
				if (((usesRelNames && exportRelNameRelationships) ||
					 (!usesRelNames && exportFkeyRelationships)) && 
					! [currentRel isDeprecated])
				{
					NSXMLElement* rel = [NSXMLElement elementWithName: @"relationship"];
					
					NSString* targetID = [NSString stringWithFormat: @"%@__%@", 
										  [(BXEntityDescription *) [currentRel destinationEntity] schemaName], 
										  [(BXEntityDescription *) [currentRel destinationEntity] name]];
					NSXMLElement* target = [NSXMLElement elementWithName: @"target" stringValue: targetID];
					
					BXRelationshipDescription* inverse = [(BXRelationshipDescription *) currentRel inverseRelationship];
					NSXMLElement* inverseName = [NSXMLElement elementWithName: @"inverseRelationship" stringValue: [inverse name]];
					
					NSXMLElement* name = [NSXMLElement elementWithName: @"name" stringValue: [currentRel name]];
					
					NSXMLElement* targetType = [NSXMLElement elementWithName: @"targetType" stringValue:
												([currentRel isToMany] ? @"many" : @"one")];
					
					[rel addChild: name];
					[rel addChild: target];
					[rel addChild: inverseName];
					[rel addChild: targetType];
					
					[rels addChild: rel];
				}
			}
			[entity addChild: rels];
		}
		
		[root addChild: entity];
	}
	
	return retval;
}
@end
