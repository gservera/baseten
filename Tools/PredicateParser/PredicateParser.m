//
// PredicateParser.m
// BaseTen
//
// Copyright 2008-2009 Marko Karppinen & Co. LLC.
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


#import <Foundation/Foundation.h>


#define kBufferSize 1024

#define BXEnumerate( LOOP_VAR, ENUMERATOR_VAR, ENUMERATION ) \
    for (id ENUMERATOR_VAR = ENUMERATION, LOOP_VAR = [ENUMERATOR_VAR nextObject]; \
            nil != LOOP_VAR; LOOP_VAR = [ENUMERATOR_VAR nextObject])


static void 
PrintIndent (int count)
{
	for (int i = 0; i < count; i++)
		printf ("    ");
}


static const char*
CompoundPredicateType (NSCompoundPredicateType type)
{
	const char* retval = "Unknown";
	switch (type)
	{
		case NSNotPredicateType:
			retval = "NOT";
			break;

		case NSAndPredicateType:
			retval = "AND";
			break;
			
		case NSOrPredicateType:
			retval = "OR";
			break;
			
		default:
			break;
	}
	return retval;
}


@interface NSPredicate (BXAdditions)
- (void) BXDescription: (int) indent;
@end


@interface NSExpression (BXAdditions)
- (void) BXDescription: (int) indent isLhs: (BOOL) isLhs;
- (void) BXDescription: (int) indent;
@end


@implementation NSPredicate (BXAdditions)
- (void) BXDescription: (int) indent
{
	PrintIndent (indent);
    printf ("Other predicate (%c): %s\n", 
        [self evaluateWithObject: nil] ? 't' : 'f',
        [[self predicateFormat] UTF8String]);
}
@end


@implementation NSCompoundPredicate (BXAdditions)
- (void) BXDescription: (int) indent
{
	PrintIndent (indent);

    char value = '?';
    @try
    {
        value = ([self evaluateWithObject: nil] ? 't' : 'f');
    }
    @catch (NSException* e)
    {
    }

    printf ("Compound predicate (%c): %s\n", 
            value, CompoundPredicateType ([self compoundPredicateType]));

    BXEnumerate (predicate, e, [[self subpredicates] objectEnumerator])
		[predicate BXDescription: indent + 1];
}
@end


@implementation NSComparisonPredicate (BXAdditions)
- (void) BXDescription: (int) indent
{
	PrintIndent (indent);

    char value = '?';
    @try
    {
        value = ([self evaluateWithObject: nil] ? 't' : 'f');
    }
    @catch (NSException* e)
    {
    }

    printf ("Comparison predicate (%c): %s\n", 
            value, [[self predicateFormat] UTF8String]);
	[[self leftExpression] BXDescription: indent + 1 isLhs: YES];
	[[self rightExpression] BXDescription: indent + 1 isLhs: NO];
}
@end


@implementation NSExpression (BXAdditions)
- (NSString *) BXExpressionDesc
{
	NSString* retval = @"";
	NSExpressionType type = [self expressionType];
	switch (type)
	{
		case NSConstantValueExpressionType:
			retval = [NSString stringWithFormat: @"Constant value: %@", [self constantValue]];
			break;
			
		case NSEvaluatedObjectExpressionType:
			retval = @"Evaluated object";
			break;
			
		case NSVariableExpressionType:
			retval = [NSString stringWithFormat: @"Variable: %@", [self variable]];
			break;
			
		case NSKeyPathExpressionType:
			retval = [NSString stringWithFormat: @"Key path: %@", [self keyPath]];
			break;
			
		case NSFunctionExpressionType:
			retval = [NSString stringWithFormat: @"Function: %@", [self function]];
			break;
			
        case 14: //NSAggregateExpressionType
			retval = @"Aggregate expression";
			break;
			
        case 13: //NSSubqueryExpressionType
			retval = @"Subquery:";
			break;
			
        case 5: //NSUnionSetExpressionType
			retval = @"Union expression";
			break;
			
        case 6: //NSIntersectSetExpressionType
			retval = @"Intersection expression";
			break;
			
        case 7: //NSMinusSetExpressionType
			retval = @"Exclusion expression";
			break;
			
		case 10:
			retval = [NSString stringWithFormat: @"Key path specifier (undocumented, type %d): %@", 
            type, [self keyPath]];
			break;
			
		default:
			retval = [NSString stringWithFormat: @"Unknown (type %d, class %@)", type, [self class]];
			break;
	}
	return retval;
}

- (void) BXSubDescriptions: (int) indent
{
	NSExpressionType type = [self expressionType];
	switch (type)
	{
		case NSFunctionExpressionType:
		{
			PrintIndent (indent);
			printf ("Operand:\n");
			[[self operand] BXDescription: indent + 1];
			PrintIndent (indent);
			printf ("Arguments:\n");
            BXEnumerate (expression, e, [[self arguments] objectEnumerator])
				[expression BXDescription: indent + 1];
			break;
		}

#if defined(MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
		case NSSubqueryExpressionType:
		{
            PrintIndent (indent);
            printf ("Variable name: %s\n", [[self variable] UTF8String]);
            
            PrintIndent (indent);
            printf ("Collection:\n");
            NSExpression* collection = [self collection];
            [collection BXDescription: 1 + indent];

			NSPredicate* predicate = [self predicate];
			[predicate BXDescription: indent];
			break;
		}
	
		case NSUnionSetExpressionType:
		case NSIntersectSetExpressionType:
		case NSMinusSetExpressionType:
		case NSAggregateExpressionType:
		{
			for (NSExpression* expression in [self collection])
				[expression BXDescription: indent];
			break;
		}
#endif

		default:
			break;
	}
		
	//end:
		;
}

- (void) BXDescription: (int) indent isLhs: (BOOL) isLhs
{
	PrintIndent (indent);
	printf ("%s: %s\n", (isLhs ? "lhs" : "rhs"), [[self BXExpressionDesc] UTF8String]);
	[self BXSubDescriptions: indent + 1];
}

- (void) BXDescription: (int) indent
{
	PrintIndent (indent);
	printf ("%s\n", [[self BXExpressionDesc] UTF8String]);
	[self BXSubDescriptions: indent + 1];
}
@end


int main (int argc, char** argv)
{
	char buffer [kBufferSize] = {};
	while (! feof (stdin))
	{
		printf ("\nEnter predicate: ");
		if (fgets (buffer, kBufferSize, stdin))
		{
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

			NSString* predicateFormat = [NSString stringWithUTF8String: buffer];
			predicateFormat = [predicateFormat stringByTrimmingCharactersInSet: 
				[NSCharacterSet whitespaceAndNewlineCharacterSet]];

			@try
			{
				NSPredicate* predicate = [NSPredicate predicateWithFormat: predicateFormat argumentArray: nil];
				[predicate BXDescription: 0];
			}
			@catch (NSException* e)
			{
				printf ("\nCaught exception: %s\n", [[e description] UTF8String]);
			}

            [pool release];
		}
	}
	return 0;
}
