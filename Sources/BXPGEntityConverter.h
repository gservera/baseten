//
// BXPGEntityConverter.h
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

@class BXPGEntityConverter;
@class BXEntityDescription;
@class NSEntityDescription;
@class PGTSConnection;


@protocol BXPGEntityConverterDelegate <NSObject>
- (BXEntityDescription *) entityConverter: (BXPGEntityConverter *) converter 
 shouldAddDropStatementFromEntityMatching: (NSEntityDescription *) importedEntity
								 inSchema: (NSString *) schemaName
									error: (NSError **) outError;
- (BOOL) entityConverter: (BXPGEntityConverter *) converter shouldCreateSchema: (NSString *) schemaName;
- (PGTSConnection *) connectionForEntityConverter: (BXPGEntityConverter *) converter;
@end


@interface BXPGEntityConverter : NSObject
{
	id <BXPGEntityConverterDelegate> mDelegate;
}
- (id <BXPGEntityConverterDelegate>) delegate;
- (void) setDelegate: (id <BXPGEntityConverterDelegate>) delegate;
- (NSArray *) statementsForEntities: (NSArray *) entityArray 
						 schemaName: (NSString *) schemaName
				   enabledRelations: (NSArray **) outArray
							 errors: (NSArray **) outErrors;
@end
