//
// BXPGForeignKeyDescription.h
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
#import <CoreData/CoreData.h>
#import <BaseTen/PGTSAbstractObjectDescription.h>
#import <BaseTen/BXForeignKey.h>
#import <pthread.h>


@interface BXPGForeignKeyDescription : PGTSAbstractDescription <BXForeignKey>
{
	NSArray *mFieldNames;
	NSInteger mIdentifier;
	NSDeleteRule mDeleteRule;
}
- (NSInteger) identifier;
- (NSDeleteRule) deleteRule;

//Thread-unsafe methods
- (void) setIdentifier: (NSInteger) identifier;
- (void) setDeleteRule: (NSDeleteRule) aRule;
- (void) setSrcFieldNames: (NSArray *) srcFields dstFieldNames: (NSArray *) dstFields;
@end
