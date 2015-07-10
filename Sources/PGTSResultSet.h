//
// PGTSResultSet.h
// BaseTen
//
// Copyright 2006-2010 Marko Karppinen & Co. LLC.
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


@class PGTSConnection;


@interface PGTSResultSet : NSObject
{
}
+ (id) resultWithPGresult: (const PGresult *) aResult connection: (PGTSConnection *) aConnection;
+ (NSError *) errorForPGresult: (const PGresult *) result;
@end


@interface PGTSResultSet (Implementation)
- (id) initWithPGResult: (const PGresult *) aResult connection: (PGTSConnection *) aConnection;
- (PGTSConnection *) connection;
- (BOOL) querySucceeded;
- (ExecStatusType) status;
- (BOOL) advanceRow;
- (id) valueForFieldAtIndex: (int) columnIndex row: (int) rowIndex;
- (id) valueForFieldAtIndex: (int) columnIndex;
- (id) valueForKey: (NSString *) aName row: (int) rowIndex;
- (BOOL) setClass: (Class) aClass forKey: (NSString *) aName;
- (BOOL) setClass: (Class) aClass forFieldAtIndex: (int) fieldIndex;
- (PGresult *) PGresult;
- (NSArray *) resultAsArray;

- (BOOL) isAtEnd;
- (int) currentRow;
- (id) currentRowAsObject;
- (void) setRowClass: (Class) aClass;
- (void) setValuesFromRow: (int) rowIndex target: (id) targetObject nullPlaceholder: (id) nullPlaceholder;
- (NSDictionary *) currentRowAsDictionary;
- (void) goBeforeFirstRow;
- (BOOL) goToRow: (int) aRow;
- (void) goBeforeFirstRowUsingFunction: (NSComparisonResult (*)(PGTSResultSet*, void*)) comparator context: (void *) context;
- (void) goBeforeFirstRowWithValue: (id) value forKey: (NSString *) columnName;
- (int) count;
- (unsigned long long) numberOfRowsAffectedByCommand;
- (NSInteger) identifier;
- (void) setIdentifier: (NSInteger) anIdentifier;
- (NSError *) error;
- (NSString *) errorString;
- (void) setUserInfo: (id) userInfo;
- (id) userInfo;

- (void) setDeterminesFieldClassesAutomatically: (BOOL) aBool;
@end


@protocol PGTSResultRowProtocol <NSObject>
/** 
 * \internal
 * \brief Called when a new result set and row index are associated with the target 
 */
- (void) PGTSSetRow: (int) row resultSet: (PGTSResultSet *) res;
@end
