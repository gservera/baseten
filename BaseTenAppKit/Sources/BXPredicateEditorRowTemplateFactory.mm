//
// BXPredicateEditorRowTemplateFactory.mm
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

#import "BXPredicateEditorRowTemplateFactory.h"
#import "BXMultipleChoicePredicateEditorRowTemplate.h"
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXCollectionFunctions.h>
#import <BaseTen/BXArraySize.h>
#import <BaseTen/BXKeyPathParser.h>


using namespace BaseTen;


@interface BXAttributeKeyPathSortKey : NSObject <NSCopying>
{
	NSArray *mOperators;
	NSAttributeType mAttributeType;
	NSComparisonPredicateModifier mModifier;
	NSUInteger mOptions;
}
@property (readonly, copy, nonatomic) NSArray *operators;
@property (readonly, nonatomic) NSAttributeType attributeType;
@property (readonly, nonatomic) NSComparisonPredicateModifier modifier;
@property (readonly, nonatomic) NSUInteger options;
- (id) initWithOperators: (NSArray *) operators 
		   attributeType: (NSAttributeType) attributeType 
				modifier: (NSComparisonPredicateModifier) modifier 
				 options: (NSUInteger) options;
@end



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



@implementation BXAttributeKeyPathSortKey
@synthesize operators = mOperators;
@synthesize attributeType = mAttributeType;
@synthesize modifier = mModifier;
@synthesize options = mOptions;

- (id) initWithOperators: (NSArray *) operators 
		   attributeType: (NSAttributeType) attributeType 
				modifier: (NSComparisonPredicateModifier) modifier 
				 options: (NSUInteger) options
{
	if ((self = [super init]))
	{
		mOperators = [operators copy];
		mAttributeType = attributeType;
		mModifier = modifier;
		mOptions = options;
	}
	return self;
}


- (void) dealloc
{
	[mOperators release];
	[super dealloc];
}


- (id) copyWithZone: (NSZone *) zone
{
	return [self retain];
}


- (NSUInteger) hash
{
	return mAttributeType ^ mModifier ^ mOptions;
}


- (BOOL) isEqual: (id) anObject
{
	BOOL retval = NO;
	if ([anObject isKindOfClass: [self class]])
	{
		// Since we are immutable, no synchronization is necessary.
		BXAttributeKeyPathSortKey *other = anObject;
		if (mAttributeType == other->mAttributeType && mModifier == other->mModifier &&
			mOptions == other->mOptions && [mOperators isEqual: other->mOperators])
		{
			retval = YES;
		}
	}
	return retval;
}
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



@implementation BXPredicateEditorRowTemplateFactory
- (id) init
{
	if ((self = [super init]))
	{
		mTypeMapping = [[NSDictionary alloc] initWithObjectsAndKeys:
						ObjectValue <NSAttributeType> (NSBooleanAttributeType),		@"bool",
						ObjectValue <NSAttributeType> (NSBinaryDataAttributeType),	@"bytea",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"char",
						ObjectValue <NSAttributeType> (NSFloatAttributeType),		@"float4",
						ObjectValue <NSAttributeType> (NSDoubleAttributeType),		@"float8",
						ObjectValue <NSAttributeType> (NSInteger16AttributeType),	@"int2",
						ObjectValue <NSAttributeType> (NSInteger32AttributeType),	@"int4",
						ObjectValue <NSAttributeType> (NSInteger64AttributeType),	@"int8",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"name",
						ObjectValue <NSAttributeType> (NSDecimalAttributeType),		@"numeric",
						ObjectValue <NSAttributeType> (NSInteger32AttributeType),	@"oid",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"text",
						ObjectValue <NSAttributeType> (NSDateAttributeType),		@"timestamp",
						ObjectValue <NSAttributeType> (NSDateAttributeType),		@"timestamptz",
						ObjectValue <NSAttributeType> (NSStringAttributeType),		@"varchar",
						nil];
	}
	return self;
}


- (NSAttributeType) attributeTypeForAttributeDescription: (BXAttributeDescription *) desc
{
	NSAttributeType retval = NSUndefinedAttributeType;
	NSString *pgType = [desc databaseTypeName];
	NSValue *attrType = [mTypeMapping objectForKey: pgType];
	if (attrType)
	{
		BaseTen::ValueGetter <NSAttributeType> getter;
		getter (attrType, &retval);
	}
	return retval;
}


- (NSArray *) operatorsForAttributeType: (NSAttributeType) attributeType 
				   attributeDescription: (BXAttributeDescription *) desc
{
	NSArray *retval = nil;
	switch (attributeType)
	{
		case NSStringAttributeType:
		{
			id operators [] = {
				ObjectValue <NSPredicateOperatorType> (NSEqualToPredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSNotEqualToPredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSMatchesPredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSLikePredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSBeginsWithPredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSEndsWithPredicateOperatorType),
				//ObjectValue <NSPredicateOperatorType> (NSInPredicateOperatorType), //Not applicable since the lhs should be a substring of rhs but that's not quite usable.
			};
			retval = [NSArray arrayWithObjects: operators count: BXArraySize (operators)];
			break;
		}
			
		case NSInteger16AttributeType:
		case NSInteger32AttributeType:
		case NSInteger64AttributeType:
		case NSDecimalAttributeType:
		case NSDoubleAttributeType:
		case NSFloatAttributeType:
		case NSDateAttributeType:
		{
			id operators [] = {
				ObjectValue <NSPredicateOperatorType> (NSLessThanPredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSLessThanOrEqualToPredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSGreaterThanPredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSGreaterThanOrEqualToPredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSEqualToPredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSNotEqualToPredicateOperatorType)
			};
			retval = [NSArray arrayWithObjects: operators count: BXArraySize (operators)];
			break;
		}
			
		case NSBooleanAttributeType:
		{
			id operators [] = {
				ObjectValue <NSPredicateOperatorType> (NSEqualToPredicateOperatorType),
				ObjectValue <NSPredicateOperatorType> (NSNotEqualToPredicateOperatorType)
			};
			retval = [NSArray arrayWithObjects: operators count: BXArraySize (operators)];
			break;
		}
			
		default: 
			break;
	}
	return retval;
}


- (NSUInteger) comparisonOptionsForAttributeType: (NSAttributeType) attributeType
							attributeDescription: (BXAttributeDescription *) desc
{
	NSUInteger retval = 0;
	if (NSStringAttributeType == attributeType)
		retval = NSCaseInsensitivePredicateOption | NSDiacriticInsensitivePredicateOption;
	return retval;
}


- (NSArray *) templatesWithDisplayNames: (NSArray *) displayNames
				   forAttributeKeyPaths: (NSArray *) keyPaths
					inEntityDescription: (BXEntityDescription *) originalEntity;
{
	// Sort key paths by attribute type, modifier and the operators.
	// (The user might want to override -operatorsForAttributeType:attributeDescription: for individual attributes.)
	// Create the templates and use the display names for display.
	
	NSDictionary *displayNamesByKeyPath = [NSDictionary dictionaryWithObjects: displayNames forKeys: keyPaths];
	NSMutableDictionary *sortedKeyPaths = [NSMutableDictionary dictionary];
	
	for (NSString *keyPath in keyPaths)
	{
		BXEntityDescription *currentEntity = originalEntity;
		NSComparisonPredicateModifier modifier = NSDirectPredicateModifier;
		BOOL inAttribute = NO;
		NSArray *components = BXKeyPathComponents (keyPath);
		BXAttributeDescription *attr = nil;
		
		for (NSString *component in components)
		{
			if (inAttribute)
			{
				[NSException raise: NSInvalidArgumentException format:
				 @"The component '%@' (key path '%@') points to an attribute, even though the end wasn't reached yet.",
				 component, keyPath];
			}
			
			BXRelationshipDescription *rel = nil;
			if ((attr = [[currentEntity attributesByName] objectForKey: component]))
				inAttribute = YES;
			else if ((rel = [[currentEntity relationshipsByName] objectForKey: component]))
			{
				currentEntity = [rel destinationEntity];
				if ([rel isToMany])
					modifier = NSAnyPredicateModifier;
			}
			else
			{
				[NSException raise: NSInvalidArgumentException format: 
				 @"Didn't find property '%@' (key path '%@') in entity %@.%@.", 
				 component, keyPath, [currentEntity schemaName], [currentEntity name]];
			}
		}
		
		if (! inAttribute)
		{
			[NSException raise: NSInvalidArgumentException format:
			 @"The key path '%@' didn't end in an attribute.", keyPath];
		}
		
		NSAttributeType attributeType = [self attributeTypeForAttributeDescription: attr];
		NSArray *operators = [self operatorsForAttributeType: attributeType attributeDescription: attr];
		NSUInteger options = [self comparisonOptionsForAttributeType: attributeType attributeDescription: attr];
		if (operators)
		{
			BXAttributeKeyPathSortKey *sortKey = [[BXAttributeKeyPathSortKey alloc] initWithOperators: operators
																						attributeType: attributeType
																							 modifier: modifier
																							  options: options];
			NSMutableArray *keyPaths = [sortedKeyPaths objectForKey: sortKey];
			if (! keyPaths)
			{
				keyPaths = [[NSMutableArray alloc] init];
				[sortedKeyPaths setObject: keyPaths forKey: sortKey];
				[keyPaths release];
			}
			[keyPaths addObject: keyPath];
			[sortKey release];
		}		
	}
	
	NSMutableArray *templates = [NSMutableArray arrayWithCapacity: [sortedKeyPaths count]];
	for (BXAttributeKeyPathSortKey *sortKey in sortedKeyPaths)
	{
		NSArray *keyPaths = [sortedKeyPaths objectForKey: sortKey];
		NSMutableArray *expressions = [NSMutableArray arrayWithCapacity: [keyPaths count]];
		for (NSString *keyPath in keyPaths)
			[expressions addObject: [NSExpression expressionForKeyPath: keyPath]];
		
		NSPredicateEditorRowTemplate *rowTemplate = nil;
		rowTemplate = [[[NSPredicateEditorRowTemplate alloc] initWithLeftExpressions: expressions
														rightExpressionAttributeType: [sortKey attributeType]
																			modifier: [sortKey modifier]
																		   operators: [sortKey operators]
																			 options: [sortKey options]] autorelease];

		for (NSMenuItem *item in [[[rowTemplate templateViews] objectAtIndex: 0] itemArray])
		{
			NSString *keyPath = [[item representedObject] keyPath];
			[item setTitle: [displayNamesByKeyPath objectForKey: keyPath]];
		}
		
		[templates addObject: rowTemplate];
	}
	
	return [[templates copy] autorelease];
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
	// Instead of display names etc., compare the primary key and the foreign key.
	
	NSArray *retval = nil;
	NSDictionary *displayNamesByRelKeyPath = [NSDictionary dictionaryWithObjects: displayNames forKeys: keyPaths];
	NSDictionary *optionDisplayNameKeyPathsByRelKeyPath = [NSDictionary dictionaryWithObjects: displayNameKeyPaths forKeys: keyPaths];
	NSMutableDictionary *sortedKeyPaths = [NSMutableDictionary dictionary];
	
	for (NSString *keyPath in sortedKeyPaths)
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
		BXRelationshipKeyPathValue *val = [sortedKeyPaths objectForKey: entity];
		NSString *keyPath = [val keyPath];
		NSComparisonPredicateModifier modifier = [val modifier];
		NSExpression *rightExpression = [NSExpression expressionForKeyPath: keyPath];
		NSString *optionDisplayNameKeyPath = [optionDisplayNameKeyPathsByRelKeyPath objectForKey: keyPath];
		NSString *displayName = [displayNamesByRelKeyPath objectForKey: keyPath];
		
		id res = [ctx executeFetchForEntity: entity 
							  withPredicate: nil 
							returningFaults: NO 
						updateAutomatically: YES 
									  error: error];
		
		if (! res)
			goto bail;
		
		BXMultipleChoicePredicateEditorRowTemplate *rowTemplate = nil;
		rowTemplate = [[BXMultipleChoicePredicateEditorRowTemplate alloc] initWithLeftExpressionOptions: res
																						rightExpression: rightExpression
																			   optionDisplayNameKeyPath: optionDisplayNameKeyPath
																			 rightExpressionDisplayName: displayName
																							   modifier: modifier];
		
		[templates addObject: rowTemplate];
		[rowTemplate release];
	}
	
	retval = [[templates copy] autorelease];
	
bail:
	return retval;
}
@end
