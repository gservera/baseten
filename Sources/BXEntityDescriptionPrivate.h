//
// BXEntityDescriptionPrivate.h
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
#import <BaseTen/BXEntityDescription.h>

@class BXDatabaseContext;
@class BXDatabaseObjectID;
@class BXRelationshipDescription;


@interface BXEntityDescription (PrivateMethods)
- (id) initWithDatabaseURI: (NSURL *) anURI table: (NSString *) tName inSchema: (NSString *) sName;
- (void) registerObjectID: (BXDatabaseObjectID *) anID;
- (void) unregisterObjectID: (BXDatabaseObjectID *) anID;
- (NSArray *) attributes: (NSArray *) strings;
- (void) setAttributes: (NSDictionary *) attributes;
- (void) resetAttributeExclusion;
- (void) setIsView: (BOOL) flag;
- (void) setRelationships: (NSDictionary *) aDict;
- (void) setHasCapability: (enum BXEntityCapability) aCapability to: (BOOL) flag;
- (void) setEnabled: (BOOL) flag;
- (id) inverseToOneRelationships;
- (void) setFetchedSuperEntities: (NSArray *) entities; //FIXME: merge with other super & sub entity methods.
- (id) fetchedSuperEntities; //FIXME: merge with other super & sub entity methods.

- (BOOL) beginValidation;
- (void) setValidated: (BOOL) flag;
- (void) endValidation;
- (void) removeValidation;
@end
