//
// BXForeignKey.h
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
#import <CoreData/CoreData.h>
#import <BaseTen/BXExport.h>

@class BXEntityDescription;
@class BXDatabaseObject;
@class BXDatabaseObjectID;


@protocol BXForeignKey <NSObject>
- (NSString *) name;
- (NSDeleteRule) deleteRule;
- (NSUInteger) numberOfColumns;
- (void) iterateColumnNames: (void (*)(NSString* srcName, NSString* dstName, void* context)) callback context: (void *) context;
- (void) iterateReversedColumnNames: (void (*)(NSString* dstName, NSString* srcName, void* context)) callback context: (void *) context;
@end


BX_EXPORT NSMutableDictionary* BXFkeySrcDictionary (id <BXForeignKey> fkey, BXEntityDescription* entity, BXDatabaseObject* valuesFrom);
BX_EXPORT NSMutableDictionary* BXFkeyDstDictionary (id <BXForeignKey> fkey, BXEntityDescription* entity, BXDatabaseObject* valuesFrom);
BX_EXPORT BXDatabaseObjectID* BXFkeySrcObjectID (id <BXForeignKey> fkey, BXEntityDescription* entity, BXDatabaseObject* valuesFrom, BOOL fireFault);
BX_EXPORT BXDatabaseObjectID* BXFkeyDstObjectID (id <BXForeignKey> fkey, BXEntityDescription* entity, BXDatabaseObject* valuesFrom, BOOL fireFault);
