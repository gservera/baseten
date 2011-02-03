//
// NSPredicate+BaseTenAdditions.m
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


#import "NSPredicate+BaseTenAdditions.h"


@interface NSPredicate (BaseTenAdditions_Tiger)
- (BOOL) evaluateWithObject: (id) anObject variableBindings: (id) bindings;
@end


@implementation NSPredicate (BaseTenAdditions)
- (BOOL) BXEvaluateWithObject: (id) object substitutionVariables: (NSDictionary *) ctx
{
	//10.5 and 10.4 have the same method but it's named differently.
	BOOL retval = NO;
	if ([self respondsToSelector: @selector (evaluateWithObject:substitutionVariables:)])
		retval = [self evaluateWithObject: object substitutionVariables: ctx];
	else
		retval = [self evaluateWithObject: object variableBindings: [[ctx mutableCopy] autorelease]];
	
	return retval;
}
@end
