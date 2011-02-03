//
// BXAttributeValuePredicateEditorRowTemplateFactory.mm
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

#import "BXAttributeValuePredicateEditorRowTemplateFactory.h"
#import "BXAttributeValuePredicateEditorRowTemplate.h"
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



@implementation BXAttributeValuePredicateEditorRowTemplateFactory
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


- (Class) rowTemplateClass
{
	return [BXAttributeValuePredicateEditorRowTemplate class];
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
		rowTemplate = [[[[self rowTemplateClass] alloc] initWithLeftExpressions: expressions
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
@end
