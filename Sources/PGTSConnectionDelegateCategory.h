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

/** See PGTSConstants.h */
/** See PGTSFunctions.m */

extern SEL kPGTSResultSetSelector;
extern SEL kPGTSQueryFailedSelector;
extern SEL kPGTSQueryDispatchSucceededSelector;
extern SEL kPGTSQueryDispatchFailedSelector;
extern SEL kPGTSConnectionReceivedNoticeSelector;

extern SEL kPGTSConnectionFailedSelector;
extern SEL kPGTSConnectionSucceededSelector;
extern SEL kPGTSStartedReconnectingSelector;
extern SEL kPGTSReconnectionFailedSelector;
extern SEL kPGTSReconnectionSucceededSelector;


@interface NSObject (PGTSConnectionDelegate)
- (void) PGTSConnection: (PGTSConnection *) connection sentQuery: (NSString *) queryString;
- (void) PGTSConnection: (PGTSConnection *) connection failedToSendQuery: (NSString *) queryString;
- (BOOL) PGTSConnection: (PGTSConnection *) connection acceptCopyingData: (NSData *) data errorMessage: (NSString **) errorMessage;
- (void) PGTSConnection: (PGTSConnection *) connection receivedData: (NSData *) data;
- (void) PGTSConnection: (PGTSConnection *) connection receivedResultSet: (PGTSResultSet *) result;
- (void) PGTSConnection: (PGTSConnection *) connection receivedError: (PGTSResultSet *) result;
- (void) PGTSConnection: (PGTSConnection *) connection receivedNotice: (NSNotification *) notice;
- (void) PGTSConnectionFailed: (PGTSConnection *) connection;
- (void) PGTSConnectionEstablished: (PGTSConnection *) connection;
- (void) PGTSConnectionStartedReconnecting: (PGTSConnection *) connection;
- (void) PGTSConnectionFailedToReconnect: (PGTSConnection *) connection;
- (void) PGTSConnectionDidReconnect: (PGTSConnection *) connection;
@end


@protocol PGTSConnectionDelegate <NSObject>
@end