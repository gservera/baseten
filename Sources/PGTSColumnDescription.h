//
// PGTSColumnDescription.h
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
#import <BaseTen/libpq-fe.h>
#import "PGTSAbstractDescription.h"


@class PGTSTypeDescription;
@class PGTSConnection;


@interface PGTSColumnDescription : PGTSAbstractDescription
{
    PGTSTypeDescription *mType;
	NSString *mDefaultValue;
    NSInteger mIndex;
	BOOL mIsNotNull;
	BOOL mIsInherited;
}

- (NSString *) quotedName: (PGTSConnection *) connection;
- (NSComparisonResult) indexCompare: (PGTSColumnDescription *) aField;
- (PGTSTypeDescription *) type;

- (NSInteger) index;
- (NSString *) defaultValue;
- (BOOL) isNotNull;
- (BOOL) isInherited;

//Thread un-safe methods.
- (void) setIndex: (NSInteger) anIndex;
- (void) setType: (PGTSTypeDescription *) anOid;
- (void) setDefaultValue: (NSString *) defaultExpression;
- (void) setNotNull: (BOOL) aBool;
- (void) setInherited: (BOOL) aBool;

//Stubs for sub classes' methods.
- (BOOL) requiresDocuments;
- (void) setRequiresDocuments: (BOOL) aBool;
@end



@interface PGTSXMLColumnDescription : PGTSColumnDescription
{
	BOOL mRequiresDocuments;
}
- (BOOL) requiresDocuments;
//Thread un-safe methods.
- (void) setRequiresDocuments: (BOOL) aBool;
@end
