//
// PGTSConnectionPrivate.h
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

#import <PGTS/PGTSResultSet.h>
#import <PGTS/PGTSConnection.h>


#define kPGTSRaiseForAsync              (1 << 0)
#define kPGTSRaiseForCompletelyAsync    (1 << 1)
#define kPGTSRaiseOnFailedQuery         (1 << 2)
#define kPGTSRaiseForConnectAsync       (1 << 3)
#define kPGTSRaiseForReconnectAsync     (1 << 4)
#define kPGTSRaiseForReceiveCopyData    (1 << 5)
#define kPGTSRaiseForSendCopyData       (1 << 6)
    
#define LogQuery( QUERY, MESSAGE_DELEGATE, PARAMETERS ) { if (YES == logsQueries) [self logQuery: QUERY message: MESSAGE_DELEGATE parameters: PARAMETERS]; }


@interface PGTSConnection (PrivateMethods)
+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *) key;
- (void) checkQueryStatus: (PGTSResultSet *) result async: (BOOL) async;
- (void) finishConnecting;
- (void) raiseExceptionForMissingSelector: (SEL) aSelector;
- (void) handleNotice: (NSString *) message;
- (void) sendFinishedConnectingMessage: (ConnStatusType) status reconnect: (BOOL) reconnected;
- (PGTSResultSet *) resultFromProxy: (volatile PGTSConnection *) proxy status: (int) status;
- (int) sendResultsToDelegate: (int) status;
- (void) handleFailedQuery;
- (void) setErrorMessage: (NSString *) aMessage;
@end


@interface PGTSConnection (ProxyMethods)
- (void) succeededToCopyData: (NSData *) data;
- (void) succeededToReceiveData: (NSData *) data;
- (void) sendDispatchStatusToDelegate: (int) status forQuery: (NSString *) queryString;
- (void) sendResultToDelegate: (PGTSResultSet *) result;
@end


@interface PGTSConnection (WorkerPrivateMethods)
- (void) workerThreadMain: (NSConditionLock *) threadLock;
- (BOOL) workerPollConnectionResetting: (BOOL) reset;
- (void) workerEnd;
- (void) workerCleanUpDisconnecting: (BOOL) disconnect;
- (void) logQuery: (NSString *) query message: (BOOL) messageDelegate parameters: (NSArray *) parameters;
- (void) logNotice: (id) anObject;
- (void) logNotification: (id) anObject;
- (void) postPGnotifications;
- (void) updateConnectionStatus;
- (void) dataAvailable;
@end
