//
// BXDatabaseObjectID.h
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

#import <Foundation/Foundation.h>
#import <BaseTen/BXConstants.h>

@class BXEntityDescription;
@class BXDatabaseContext;
@class BXAttributeDescription;

@interface BXDatabaseObjectID : NSObject 
{
    BOOL                        mRegistered;
    NSUInteger                  mHash;
    NSURL*                      mURIRepresentation;
    BXEntityDescription*		mEntity;
}

+ (NSURL *) URIRepresentationForEntity: (BXEntityDescription *) anEntity primaryKeyFields: (NSDictionary *) pkeyDict;
+ (BOOL) parseURI: (NSURL *) anURI
           entity: (NSString **) outEntityName
           schema: (NSString **) outSchemaName
 primaryKeyFields: (NSDictionary **) outPkeyDict;

- (id) initWithURI: (NSURL *) anURI context: (BXDatabaseContext *) context;
- (id) initWithURI: (NSURL *) anURI context: (BXDatabaseContext *) context error: (NSError **) error BX_DEPRECATED_IN_1_8;
- (NSURL *) URIRepresentation;

- (BXEntityDescription *) entity;
- (NSPredicate *) predicate;
- (BOOL) isEqual: (id) anObject;
@end


@interface BXDatabaseObjectID (NSCopying) <NSCopying, NSMutableCopying>
@end
