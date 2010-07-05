//
// BXMultipleChoicePredicateEditorRowTemplateFactory.m
// BaseTen
//
// Copyright (C) 2010 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://www.karppinen.fi/baseten/licensing/ or by contacting
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

#import "BXMultipleChoicePredicateEditorRowTemplateFactory.h"
#import "BXMultipleChoicePredicateEditorRowTemplate.h"
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXKeyPathParser.h>



@interface BXRelationshipKeyPathValue : NSObject
{
	NSString *mKeyPath;
	NSComparisonPredicateModifier mModifier;
}
@property (readonly, nonatomic) NSString *keyPath;
@property (readonly, nonatomic) NSComparisonPredicateModifier modifier;
- (id) initWithKeyPath: (NSString *) keyPath
			  modifier: (NSComparisonPredicateModifier) modifier;
@end



@implementation BXRelationshipKeyPathValue
@synthesize keyPath = mKeyPath;
@synthesize modifier = mModifier;

- (id) initWithKeyPath: (NSString *) keyPath modifier: (NSComparisonPredicateModifier) modifier
{
	if ((self = [super init]))
	{
		mKeyPath = [keyPath copy];
		mModifier = modifier;
	}
	return self;
}


- (void) dealloc
{
	[mKeyPath release];
	[super dealloc];
}
@end



@implementation BXMultipleChoicePredicateEditorRowTemplateFactory
// Needs to be a subclass of BXMultipleChoicePredicateEditorRowTemplate.
- (Class) rowTemplateClass
{
	return [BXMultipleChoicePredicateEditorRowTemplate class];
}


- (NSArray *) multipleChoiceTemplatesWithDisplayNames: (NSArray *) displayNames
						 andOptionDisplayNameKeyPaths: (NSArray *) displayNameKeyPaths
							  forRelationshipKeyPaths: (NSArray *) keyPaths
								  inEntityDescription: (BXEntityDescription *) originalEntity
									  databaseContext: (BXDatabaseContext *) ctx
												error: (NSError **) error
{
	// Fetch all objects from the entity at the relationship key path end.
	// For each object just the corresponding display name key path for the display name.
	
	NSArray *retval = nil;
	NSDictionary *displayNamesByRelKeyPath = [NSDictionary dictionaryWithObjects: displayNames forKeys: keyPaths];
	NSDictionary *optionDisplayNameKeyPathsByRelKeyPath = [NSDictionary dictionaryWithObjects: displayNameKeyPaths forKeys: keyPaths];
	NSMutableDictionary *sortedKeyPaths = [NSMutableDictionary dictionary];
	
	for (NSString *keyPath in keyPaths)
	{
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
		[val release];
	}
	
	NSMutableArray *templates = [NSMutableArray array];
	for (BXEntityDescription *entity in sortedKeyPaths)
	{
		id res = [ctx executeFetchForEntity: entity 
							  withPredicate: nil 
							returningFaults: NO 
						updateAutomatically: YES 
									  error: error];
		
		if (! res)
			goto bail;
		
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
			[rowTemplate release];			
		}
	}
	
	retval = [[templates copy] autorelease];
	
bail:
	return retval;
}
@end
