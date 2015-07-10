//
// PGTSConnectionDelegate.h
// BaseTen
//
// Copyright 2006-2008 Marko Karppinen & Co. LLC.
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

#import <PGTS/PGTSConstants.h>
#import <PGTS/postgresql/libpq-fe.h>

/** See PGTSConstants.h */
/** See PGTSConstants.m */
/** See PGTSFunctions.m */

/** Selectors for delegate methods */
//@{
PGTS_EXPORT SEL kPGTSSentQuerySelector;
PGTS_EXPORT SEL kPGTSFailedToSendQuerySelector;
PGTS_EXPORT SEL kPGTSAcceptCopyingDataSelector;
PGTS_EXPORT SEL kPGTSReceivedDataSelector;
PGTS_EXPORT SEL kPGTSReceivedResultSetSelector;
PGTS_EXPORT SEL kPGTSReceivedErrorSelector;
PGTS_EXPORT SEL kPGTSReceivedNoticeSelector;

PGTS_EXPORT SEL kPGTSConnectionFailedSelector;
PGTS_EXPORT SEL kPGTSConnectionEstablishedSelector;
PGTS_EXPORT SEL kPGTSStartedReconnectingSelector;
PGTS_EXPORT SEL kPGTSDidReconnectSelector;
//@}


@class PGTSConnection;
@class PGTSResultSet;

/** Informal part of the protocol */
@interface NSObject (PGTSConnectionDelegate)
/** Callbacks for asynchronous query methods */
//@{
- (void) PGTSConnection: (PGTSConnection *) connection sentQuery: (NSString *) queryString;
- (void) PGTSConnection: (PGTSConnection *) connection failedToSendQuery: (NSString *) queryString;
- (void) PGTSConnection: (PGTSConnection *) connection receivedResultSet: (PGTSResultSet *) result;
- (void) PGTSConnection: (PGTSConnection *) connection receivedError: (PGTSResultSet *) result;
- (void) PGTSConnection: (PGTSConnection *) connection receivedNotice: (NSNotification *) notice;
//@}
/** Callback for sendCopyData: and sendCopyData:pakcetSize: */
- (BOOL) PGTSConnection: (PGTSConnection *) connection acceptCopyingData: (NSData *) data errorMessage: (NSString **) errorMessage;
/** Callback for receiveCopyData */
- (void) PGTSConnection: (PGTSConnection *) connection receivedData: (NSData *) data;

/** Callbacks for asynchronous connecting and reconnecting */
//@{
- (void) PGTSConnectionFailed: (PGTSConnection *) connection;
- (void) PGTSConnectionEstablished: (PGTSConnection *) connection;
- (void) PGTSConnectionStartedReconnecting: (PGTSConnection *) connection;
- (void) PGTSConnectionDidReconnect: (PGTSConnection *) connection;
//@}
@end


/** Formal part of the protocol */
@protocol PGTSConnectionDelegate <NSObject>
@end


@interface NSObject (PGTSNotifierDelegate)
- (BOOL) PGTSNotifierShouldHandleNotification: (NSNotification *) notification fromTableWithOid: (Oid) oid;
@end