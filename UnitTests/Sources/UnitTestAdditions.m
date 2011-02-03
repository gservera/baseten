//
// UnitTestAdditions.m
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

#import "UnitTestAdditions.h"
#import <BaseTen/BXRelationshipDescriptionPrivate.h>


@implementation BXDatabaseObject (UnitTestAdditions)
- (id) resolveNoncachedRelationshipNamed: (NSString *) aName
{
	NSError* error = nil;
	//BXDatabaseObject caches related objects so for testing purposes we need to fetch using the relationship.
	BXEntityDescription* entity = [[self objectID] entity];
	BXRelationshipDescription* rel = [[entity relationshipsByName] objectForKey: aName];
	id rval = [rel targetForObject: self error: &error];
	NSAssert (nil == error, [error description]);
	return rval;
}
@end