//
// BXMultipleChoicePredicateEditorRowTemplateFactory.m
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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

#import "BXMultipleChoicePredicateEditorRowTemplateFactory.h"
#import "BXMultipleChoicePredicateEditorRowTemplate.h"
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXKeyPathParser.h>

@interface BXRelationshipKeyPathValue : NSObject

- (instancetype)initWithKeyPath:(NSString*)kP modifier:(NSComparisonPredicateModifier)mod;

@property (readonly, nonatomic) NSString *keyPath;
@property (readonly, nonatomic) NSComparisonPredicateModifier modifier;
@end

@implementation BXRelationshipKeyPathValue

- (instancetype)initWithKeyPath:(NSString*)kP modifier:(NSComparisonPredicateModifier)mod {
    self = [super init];
    if (self) {
        _keyPath = [kP copy];
        _modifier = mod;
    }
    return self;
}

@end


@implementation BXMultipleChoicePredicateEditorRowTemplateFactory
// Needs to be a subclass of BXMultipleChoicePredicateEditorRowTemplate.
- (Class) rowTemplateClass {
	return [BXMultipleChoicePredicateEditorRowTemplate class];
}

- (NSArray *) multipleChoiceTemplatesWithDisplayNames:(NSArray *)displayNames
						 andOptionDisplayNameKeyPaths:(NSArray *)displayNameKeyPaths
							  forRelationshipKeyPaths:(NSArray *)keyPaths
								  inEntityDescription:(BXEntityDescription *)originalEntity
									  databaseContext:(BXDatabaseContext *)ctx
												error:(NSError **)error {
	// Fetch all objects from the entity at the relationship key path end.
	// For each object just the corresponding display name key path for the display name.
	
	NSArray *retval = nil;
	NSDictionary *displayNamesByRelKeyPath = [NSDictionary dictionaryWithObjects: displayNames forKeys: keyPaths];
	NSDictionary *optionDisplayNameKeyPathsByRelKeyPath = [NSDictionary dictionaryWithObjects: displayNameKeyPaths forKeys: keyPaths];
	NSMutableDictionary *sortedKeyPaths = [NSMutableDictionary dictionary];
	
	for (NSString *keyPath in keyPaths) {
		BXEntityDescription *currentEntity = originalEntity;
		NSComparisonPredicateModifier modifier = NSDirectPredicateModifier;
		NSArray *components = BXKeyPathComponents (keyPath);
		BXRelationshipDescription *rel = nil;
		
		for (NSString *component in components)
		{			
			if ((rel = [[currentEntity relationshipsByName] objectForKey: component]))
			{
				currentEntity = [rel destinationEntity];
				if ([rel isToMany])
					modifier = NSAnyPredicateModifier;
			}
			else if ([[currentEntity attributesByName] objectForKey: component])
			{
				[NSException raise: NSInvalidArgumentException format:
				 @"The component '%@' (key path '%@') points to an attribute, but a relationship was expected.",
				 component, keyPath];				
			}
			else
			{
				[NSException raise: NSInvalidArgumentException format: 
				 @"Didn't find property '%@' (key path '%@') in entity %@.%@.", 
				 component, keyPath, [currentEntity schemaName], [currentEntity name]];
			}
		}
		
		NSMutableArray *keyPaths = [sortedKeyPaths objectForKey: currentEntity];
		if (! keyPaths)
		{
			keyPaths = [NSMutableArray array];
			[sortedKeyPaths setObject: keyPaths forKey: currentEntity];
		}
		
		BXRelationshipKeyPathValue *val = [[BXRelationshipKeyPathValue alloc] initWithKeyPath: keyPath modifier: modifier];
		[keyPaths addObject: val];
	}
	
	NSMutableArray *templates = [NSMutableArray array];
	for (BXEntityDescription *entity in sortedKeyPaths)
	{
		id res = [ctx executeFetchForEntity: entity 
							  withPredicate: nil 
							returningFaults: NO 
						updateAutomatically: YES 
									  error: error];
		
        if (! res) {
            return retval;
        }
		
		for (BXRelationshipKeyPathValue *val in [sortedKeyPaths objectForKey: entity])
		{
			NSString *keyPath = [val keyPath];
			NSComparisonPredicateModifier modifier = [val modifier];
			NSExpression *leftExpression = [NSExpression expressionForKeyPath: keyPath];
			NSString *optionDisplayNameKeyPath = [optionDisplayNameKeyPathsByRelKeyPath objectForKey: keyPath];
			NSString *displayName = [displayNamesByRelKeyPath objectForKey: keyPath];		
			
			BXMultipleChoicePredicateEditorRowTemplate *rowTemplate = nil;
			rowTemplate = [[[self rowTemplateClass] alloc] initWithLeftExpression: leftExpression
														   rightExpressionOptions: res
														 optionDisplayNameKeyPath: optionDisplayNameKeyPath
														leftExpressionDisplayName: displayName
																		 modifier: modifier];
			
			[templates addObject: rowTemplate];
		}
	}
    return [templates copy];;
}
@end
