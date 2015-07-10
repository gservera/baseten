//
// BXMultipleChoicePredicateEditorRowTemplateFactory.h
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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

@import Foundation;
@class BXEntityDescription;
@class BXDatabaseContext;

@interface BXMultipleChoicePredicateEditorRowTemplateFactory : NSObject

- (NSArray*)multipleChoiceTemplatesWithDisplayNames:(NSArray*) displayNames
                       andOptionDisplayNameKeyPaths: (NSArray *) displayNameKeyPaths
                            forRelationshipKeyPaths: (NSArray *) keyPaths
                                inEntityDescription: (BXEntityDescription *) originalEntity
                                    databaseContext:(BXDatabaseContext *) ctx
                                              error:(NSError **)err;

- (Class)rowTemplateClass;
@end
