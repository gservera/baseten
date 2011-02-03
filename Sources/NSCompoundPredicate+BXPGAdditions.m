//
// NSCompoundPredicate+BXPGAdditions.m
// BaseTen
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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

#import "NSPredicate+PGTSAdditions.h"
#import "NSCompoundPredicate+BXPGAdditions.h"
#import "BXLogger.h"
#import "BXEnumerate.h"
#import "PGTSConstants.h"


@implementation NSCompoundPredicate (BXPGAdditions)
- (void) BXPGVisit: (id <BXPGPredicateVisitor>) visitor
{
	switch ([self compoundPredicateType])
	{
		case NSNotPredicateType:
			[visitor visitNotPredicate: self];
			break;
			
		case NSAndPredicateType:
			[visitor visitAndPredicate: self];
			break;
			
		case NSOrPredicateType:
			[visitor visitOrPredicate: self];
			break;
			
		default:
			[visitor visitUnknownPredicate: self];
			break;
	}
}

//FIXME: This is only used with SQL schema generation. It should be removed in a future revision.
- (NSString *) PGTSExpressionWithObject: (id) anObject context: (NSMutableDictionary *) context
{
    BXAssertValueReturn (nil != [context objectForKey: kPGTSConnectionKey], nil, 
						 @"Did you remember to set connection to %@ in context?", kPGTSConnectionKey);
    NSString* retval = nil;
    NSArray* subpredicates = [self subpredicates];
    NSMutableArray* parts = [NSMutableArray arrayWithCapacity: [subpredicates count]];
    BXEnumerate (currentPredicate, e, [subpredicates objectEnumerator])
	{
		NSString* expression = [currentPredicate PGTSExpressionWithObject: anObject context: context];
		if (expression)
			[parts addObject: expression];
	}
    
    NSString* glue = nil;
    NSCompoundPredicateType type = [self compoundPredicateType];
	if (0 < [parts count])
	{
		if (NSNotPredicateType == type)
			retval = [NSString stringWithFormat: @"(NOT %@)", [parts objectAtIndex: 0]];
		else
		{
			switch (type)
			{
				case NSAndPredicateType:
					glue = @" AND ";
					break;
				case NSOrPredicateType:
					glue = @" OR ";
					break;
				default:
					[NSException raise: NSInvalidArgumentException 
								format: @"Unexpected compound predicate type: %d.", type];
					break;
			}
			retval = [NSString stringWithFormat: @"(%@)", [parts componentsJoinedByString: glue]];
		}
    }
    return retval;
}
@end
