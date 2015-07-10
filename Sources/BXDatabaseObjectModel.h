//
// BXDatabaseObjectModel.h
// BaseTen
//
// Copyright 2009-2010 Marko Karppinen & Co. LLC.
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

@class BXDatabaseObjectModelStorage;
@class BXDatabaseContext;
@class BXEntityDescription;
@class NSEntityDescription;


@interface BXDatabaseObjectModel : NSObject 
{
	BXDatabaseObjectModelStorage* mStorage;
	NSURL* mStorageKey;
	NSMutableDictionary* mEntitiesBySchemaAndName;
	volatile NSInteger mConnectionCount;
	volatile BOOL mReloading;
}
+ (NSError *) errorForMissingEntity: (NSString *) name inSchema: (NSString *) schemaName;

- (BOOL) canCreateEntityDescriptions;

- (NSArray *) entities;
- (BXEntityDescription *) entityForTable: (NSString *) tableName;
- (BXEntityDescription *) entityForTable: (NSString *) tableName inSchema: (NSString *) schemaName;
- (NSDictionary *) entitiesBySchemaAndName: (BXDatabaseContext *) context reload: (BOOL) shouldReload error: (NSError **) outError;

- (BOOL) entity: (NSEntityDescription *) entity existsInSchema: (NSString *) schemaName;
- (BXEntityDescription *) matchingEntity: (NSEntityDescription *) entity inSchema: (NSString *) schemaName;
@end
