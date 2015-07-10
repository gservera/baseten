//
// NSPredicate+PGTSAdditions.m
// BaseTen
//
// Copyright 2006-2008 Marko Karppinen & Co. LLC.
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
#import "NSExpression+PGTSAdditions.h"
#import "BXLogger.h"
#import "PGTSConstants.h"


@implementation NSPredicate (BXPGAdditions)
- (void) BXPGVisit: (id <BXPGPredicateVisitor>) visitor
{
    Class tpClass = NSClassFromString (@"NSTruePredicate");
    Class fpClass = NSClassFromString (@"NSFalsePredicate");
    if (nil != tpClass && [self isKindOfClass: tpClass])
		[visitor visitTruePredicate: self];
    else if (nil != fpClass && [self isKindOfClass: fpClass])
		[visitor visitFalsePredicate: self];
	else
		[visitor visitUnknownPredicate: self];
}

//FIXME: This is only used with SQL schema generation. It should be removed in a future revision.
- (NSString *) PGTSExpressionWithObject: (id) anObject context: (NSMutableDictionary *) context
{
    NSString* retval = nil;
    Class tpClass = NSClassFromString (@"NSTruePredicate");
    Class fpClass = NSClassFromString (@"NSFalsePredicate");
    if (nil != tpClass && [self isKindOfClass: tpClass])
        retval = @"(true)";
    else if (nil != fpClass && [self isKindOfClass: fpClass])
        retval = @"(false)";
	//Otherwise we return nil since this method gets overridden anyway.
    return retval;
}
@end
