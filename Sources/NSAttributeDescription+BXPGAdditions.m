//
// NSAttributeDescription+BXPGAdditions.m
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

#import "NSAttributeDescription+BXPGAdditions.h"
#import "NSPredicate+PGTSAdditions.h"
#import "BXHOM.h"
#import "BXVerbatimExpressionValue.h"
#import "BXLogger.h"
#import "PGTSFoundationObjects.h"
#import "PGTSConstants.h"
#import "BXEnumerate.h"
#import "BXError.h"


@implementation NSAttributeDescription (BXPGAdditions)
+ (NSString *) BXPGNameForAttributeType: (NSAttributeType) type
{
    NSString* retval = nil;
    switch (type)
    {        
        case NSInteger16AttributeType:
            retval =  @"smallint";
            break;
            
        case NSInteger32AttributeType:
            retval = @"integer";
            break;
            
        case NSInteger64AttributeType:
            retval = @"bigint";
            break;
            
        case NSDecimalAttributeType:
            retval = @"numeric";
            break;
            
        case NSDoubleAttributeType:
            retval = @"double precision";
            break;
            
        case NSFloatAttributeType:
            retval = @"real";
            break;
            
        case NSStringAttributeType:
            retval = @"text";
            break;
            
        case NSBooleanAttributeType:
            retval = @"boolean";
            break;
            
        case NSDateAttributeType:
            retval = @"timestamp with time zone";
            break;
            
        case NSBinaryDataAttributeType:
            retval = @"bytea";
            break;
            
        case NSUndefinedAttributeType:
		case NSTransformableAttributeType:
        default:
            break;            
    }
    return retval;
}


- (NSMutableSet *) BXPGParentPredicates
{
	NSString* name = [self name];
	NSEntityDescription* parent = [self entity];
	NSMutableSet* parentPredicates = [NSMutableSet set];
	while (nil != (parent = [parent superentity]))
	{
		NSAttributeDescription* parentAttribute = [[parent attributesByName] objectForKey: name];
		if (! parentAttribute)
			break;
		
		[parentPredicates addObjectsFromArray: [parentAttribute validationPredicates]];
	}
	
	return parentPredicates;
}


- (void) BXPGPredicate: (NSPredicate *) givenPredicate 
			 lengthExp: (NSExpression *) lengthExp 
			 maxLength: (NSInteger *) maxLength
{
	if ([givenPredicate isKindOfClass: [NSComparisonPredicate class]])
	{
		NSComparisonPredicate* predicate = (NSComparisonPredicate *) givenPredicate;
		NSExpression* lhs = [predicate leftExpression];
		NSExpression* rhs = [predicate rightExpression];
		NSPredicateOperatorType operator = [predicate predicateOperatorType];
		
		BOOL doTest = NO;
		NSInteger value = 0;
		if ([lhs isEqual: lengthExp] && NSConstantValueExpressionType == [rhs expressionType])
		{
			value = [[rhs constantValue] integerValue];
			switch (operator)
			{
				case NSLessThanPredicateOperatorType:
					value--;
				case NSLessThanOrEqualToPredicateOperatorType:
					doTest = YES;
					break;
                default: //?: New
                    break;
			}
		}
		else if ([rhs isEqual: lengthExp] && NSConstantValueExpressionType == [lhs expressionType])
		{
			value = [[lhs constantValue] integerValue];
			switch (operator)
			{
				case NSGreaterThanPredicateOperatorType:
					value--;
				case NSGreaterThanOrEqualToPredicateOperatorType:
					doTest = YES;
					break;
                default: //?: New
                    break;
			}
		}
		
		if (doTest && value < *maxLength)
			*maxLength = value;
	}
}


- (NSInteger) BXPGMaxLength
{
	NSInteger retval = NSIntegerMax;
	
	NSMutableSet* predicates = [self BXPGParentPredicates];
	[predicates addObjectsFromArray: [self validationPredicates]];
	
	NSExpression* lengthExp = [NSExpression expressionForKeyPath: @"length"];
	[[predicates BX_Visit: self] BXPGPredicate: nil lengthExp: lengthExp maxLength: &retval];
	
	if (retval <= 0)
		retval = NSIntegerMax;
	
	return retval;
}


- (NSString *) BXPGValueType
{
	NSString* retval = nil;
	NSAttributeType attrType = [self attributeType];
	NSInteger maxLength = NSIntegerMax;
	if (NSStringAttributeType == attrType && NSIntegerMax != (maxLength = [self BXPGMaxLength]))
		retval = [NSString stringWithFormat: @"VARCHAR (%ld)", (long)maxLength];
	else
		retval = [[self class] BXPGNameForAttributeType: attrType];
	return retval;
}


static NSExpression*
CharLengthExpression (NSString* name)
{
	NSString* fcall = [NSString stringWithFormat: @"char_length (\"%@\")", name];
	BXVerbatimExpressionValue* value = [BXVerbatimExpressionValue valueWithString: fcall];
	NSExpression* retval = [NSExpression expressionForConstantValue: value];
	return retval;
}

//FIXME: this could be moved to NSKeyPathExpression handling in NSExpression+PGTSAdditions.
- (NSPredicate *) BXPGTransformPredicate: (NSPredicate *) givenPredicate
{
	NSPredicate* retval = givenPredicate;
	NSAttributeType attrType = [self attributeType];
	//FIXME: handle more special cases? Are there any?
	switch (attrType) 
	{
		case NSStringAttributeType:
		{
			//FIXME: this could be generalized. We don't iterate subpredicates because Xcode data modeler doesn't create compound predicates.
			if ([givenPredicate isKindOfClass: [NSComparisonPredicate class]])
			{
				NSComparisonPredicate* predicate = (NSComparisonPredicate *) givenPredicate;
				NSExpression* lhs = [predicate leftExpression];
				NSExpression* rhs = [predicate rightExpression];
				NSPredicateOperatorType op = [predicate predicateOperatorType];
				NSExpression* lenghtExp = [NSExpression expressionForKeyPath: @"length"];
				if ([lhs isEqual: lenghtExp])
				{
					switch (op)
					{
						case NSEqualToPredicateOperatorType:
						case NSGreaterThanPredicateOperatorType:
						case NSGreaterThanOrEqualToPredicateOperatorType:
						{
							NSExpression* lhs = CharLengthExpression ([self name]);
							retval = [NSComparisonPredicate predicateWithLeftExpression: lhs rightExpression: rhs 
																			   modifier: [predicate comparisonPredicateModifier] 
																				   type: op
																				options: [predicate options]];
							break;
						}
							
						default:
							retval = nil;
							break;
					}
				}
				else if ([rhs isEqual: lenghtExp])
				{
					switch (op)
					{
						case NSEqualToPredicateOperatorType:
						case NSLessThanPredicateOperatorType:
						case NSLessThanOrEqualToPredicateOperatorType:
						{
							NSExpression* rhs = CharLengthExpression ([self name]);
							retval = [NSComparisonPredicate predicateWithLeftExpression: lhs rightExpression: rhs 
																			   modifier: [predicate comparisonPredicateModifier] 
																				   type: op
																				options: [predicate options]];
							break;
						}
							
						default:
							retval = nil;
							break;
					}
				}
				else
				{
					//FIXME: report the error in some other way. We don't understand other key paths than length.
					BXLogError (@"Predicate %@ wasn't understood.", [predicate predicateFormat]);
					retval = nil;
				}
			}
			break;
		}
			
		default:
			break;
	}
	return retval;
}


- (NSArray *) BXPGAttributeConstraintsInSchema: (NSString *) schemaName
{
	NSString* name = [self name];
	NSString* entityName = [[self entity] name];
	NSMutableArray* retval = [NSMutableArray arrayWithCapacity: 2];
		
	if (! [self isOptional])
	{
		NSString* format = @"ALTER TABLE \"%@\".\"%@\" ALTER COLUMN \"%@\" SET NOT NULL;";
		[retval addObject: [NSString stringWithFormat: format, schemaName, entityName, name]];
	}
	
	return retval;
}


- (NSArray *) BXPGConstraintsForValidationPredicatesInSchema: (NSString *) schemaName
												  connection: (PGTSConnection *) connection
{
	NSString* name = [self name];
	NSString* entityName = [[self entity] name];
	NSArray* givenValidationPredicates = [self validationPredicates];
	NSMutableArray* retval = [NSMutableArray arrayWithCapacity: [givenValidationPredicates count]];
	
	//Check parent's validation predicates so that we don't create the same predicates two times.
	NSSet* parentPredicates = [self BXPGParentPredicates];
	NSString* format = @"ALTER TABLE \"%@\".\"%@\" ADD CHECK (%@);"; //Patch by Tim Bedford 2008-08-06.
	BXEnumerate (currentPredicate, e, [givenValidationPredicates objectEnumerator])
	{
		//Skip if parent has this one.
		if ([parentPredicates containsObject: currentPredicate])
			continue;
		
		//Check that the predicate may be resolved in the database.
		currentPredicate = [self BXPGTransformPredicate: currentPredicate];
		if (! currentPredicate)
			continue;
		
		NSMutableDictionary* ctx = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									connection, kPGTSConnectionKey,
									[NSNumber numberWithBool: YES], kPGTSExpressionParametersVerbatimKey,
									nil];
		NSString* SQLExpression = [currentPredicate PGTSExpressionWithObject: name context: ctx];
		NSMutableString* constraint = [NSMutableString stringWithFormat: format, schemaName, entityName, SQLExpression];
		[retval addObject: constraint];
	}
	
	return retval;
}


- (NSString *) BXPGAttributeDefinition: (PGTSConnection *) connection
{
	NSString* typeDefinition = [self BXPGValueType];
	NSString* addition = @"";
	id defaultValue = [self defaultValue];
	if (defaultValue)
	{
		NSString* defaultExp = [defaultValue PGTSExpressionOfType: [self attributeType] connection: connection];
		if (defaultExp)
			addition = [NSString stringWithFormat: @"DEFAULT %@", defaultExp];
	}
	return [NSString stringWithFormat: @"\"%@\" %@ %@", [self name], typeDefinition, addition];
}


static NSError*
ImportError (NSString* message, NSString* reason)
{
	Expect (message);
	Expect (reason);
	
	//FIXME: set the domain and the code.
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  message, NSLocalizedFailureReasonErrorKey,
							  reason, NSLocalizedRecoverySuggestionErrorKey,
							  nil];
	NSError* retval = [BXError errorWithDomain: @"" code: 0 userInfo: userInfo];
	return retval;
}


- (BOOL) BXCanAddAttribute: (NSError **) outError
{
	BOOL retval = NO;
	NSString* errorFormat = @"Skipped attribute %@ in %@.";
	NSError* localError = nil;
	
	if (! [self isTransient])
	{
		switch ([self attributeType]) 
		{
			case NSUndefinedAttributeType:
			{
				NSString* errorString = [NSString stringWithFormat: errorFormat, [self name], [[self entity] name]];
				localError = ImportError (errorString, @"Attributes with undefined type are not supported.");
				break;
			}
				
			case NSTransformableAttributeType:
			{
				NSString* errorString = [NSString stringWithFormat: errorFormat, [self name], [[self entity] name]];
				localError = ImportError (errorString, @"Attributes with transformable type are not supported.");
				break;
			}
				
			default:
				retval = YES;
				break;
		}
	}
	
	if (outError)
		*outError = localError;
	return retval;
}
@end
