//
// BXPGEntityImporter.h
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
#import <BaseTen/BXPGEntityConverter.h>
@class BXDatabaseContext;
@class BXPGEntityImporter;


@protocol BXPGEntityImporterDelegate <NSObject>
- (void) entityImporterAdvanced: (BXPGEntityImporter *) importer;
- (void) entityImporter: (BXPGEntityImporter *) importer finishedImporting: (BOOL) succeeded error: (NSError *) error;
@end


@interface BXPGEntityImporter : NSObject 
{
	BXDatabaseContext* mContext;
	BXPGEntityConverter* mEntityConverter;
	NSArray* mEntities;
	NSString* mSchemaName;
	NSArray* mStatements;
	NSArray* mEnabledRelations;
	id <BXPGEntityImporterDelegate> mDelegate;
}
- (void) setDatabaseContext: (BXDatabaseContext *) aContext;
- (void) setEntities: (NSArray *) aCollection;
- (void) setSchemaName: (NSString *) aName;
- (void) setDelegate: (id <BXPGEntityImporterDelegate>) anObject;

- (NSArray *) importStatements;
- (NSArray *) importStatements: (NSArray **) outErrors;
- (void) importEntities;
- (BOOL) enableEntities: (NSError **) outError;
- (BOOL) disableEntities: (NSArray *) entities error: (NSError **) outError;
@end


@interface BXPGEntityImporter (BXPGEntityConverterDelegate) <BXPGEntityConverterDelegate>
@end
