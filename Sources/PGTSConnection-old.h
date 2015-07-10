//
// PGTSConnection.h
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

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/time.h>
#import <PGTS/postgresql/libpq-fe.h>



@class PGTSResultSet;
@class PGTSDatabaseInfo;
@protocol PGTSConnectionDelegate;
@protocol PGTSCertificateVerificationDelegate;


@interface PGTSConnection : NSObject 
{
    @public
    unsigned int exceptionTable;

    @protected
	PGconn* connection;			//Deallocated in disconnect
    PGcancel* cancelRequest;	//Deallocated in disconnect
    
    CFSocketRef socket;												//Deallocated in workerThreadMain
	CFRunLoopSourceRef socketSource;								//Deallocated in workerThreadMain
    volatile PGTSConnection *workerProxy, *returningWorkerProxy;	//Deallocated in workerThreadMain
	volatile PGTSConnection *mainProxy, *returningMainProxy;		//Deallocated in endWorkerThread
	
    PGTSDatabaseInfo* databaseInfo; //Weak
	Class resultSetClass;			//Weak
    id delegate;					//Weak

    NSNotificationCenter* postgresNotificationCenter;
    NSCountedSet* notificationCounts;
    NSMutableDictionary* notificationAssociations;

	NSLock* connectionLock;	
    NSConditionLock* asyncConnectionLock;
    NSLock* workerThreadLock;
	
    NSString* connectionString;
    id parameterCounts;
    NSMutableDictionary* deserializationDictionary;
    NSString* initialCommands;

	volatile ConnStatusType connectionStatus;
    struct timeval timeout;
	
	NSString* errorMessage;
	
	id <PGTSCertificateVerificationDelegate> certificateVerificationDelegate;

	BOOL connectsAutomatically;
    BOOL reconnectsAutomatically;
    BOOL overlooksFailedQueries;
    BOOL delegateProcessesNotices;
	
    volatile BOOL logsQueries;
	volatile BOOL shouldContinueThread;
    volatile BOOL threadRunning;
    volatile BOOL failedToSendQuery;
	
    volatile BOOL messageDelegateAfterConnecting;
	volatile BOOL sslSetUp;
	BOOL connecting;
	BOOL connectingAsync;
}

+ (PGTSConnection *) connection;
- (id) disconnectedCopy;

- (ConnStatusType) connect;
- (ConnStatusType) reconnect;
- (void) disconnect;

//FIXME: this could be named differently
- (void) endWorkerThread;

- (BOOL) connectAsync;
- (BOOL) reconnectAsync;

- (NSNotificationCenter *) postgresNotificationCenter;
- (void) startListening: (id) anObject forNotification: (NSString *) notificationName selector: (SEL) aSelector;
- (void) startListening: (id) anObject forNotification: (NSString *) notificationName 
               selector: (SEL) aSelector sendQuery: (BOOL) sendQuery;
- (void) stopListening: (id) anObject forNotification: (NSString *) notificationName;
- (void) stopListening: (id) anObject;

@end


@interface PGTSConnection (MiscAccessors)
+ (BOOL) hasSSLCapability;

- (PGconn *) pgConnection;
- (BOOL) setConnectionURL: (NSURL *) url;
- (void) setConnectionDictionary: (NSDictionary *) userDict;
- (void) setConnectionString: (NSString *) connectionString;
- (NSString *) connectionString;

- (BOOL) overlooksFailedQueries;
- (void) setOverlooksFailedQueries: (BOOL) aBool;
- (id <PGTSConnectionDelegate>) delegate;
- (void) setDelegate: (id <PGTSConnectionDelegate>) anObject;

- (BOOL) connectsAutomatically;
- (void) setConnectsAutomatically: (BOOL) aBool;
- (NSString *) initialCommands;
- (void) setInitialCommands: (NSString *) aString;

- (ConnStatusType) status;

- (struct timeval) timeout;
- (void) setTimeout: (struct timeval) value;

- (PGTSDatabaseInfo *) databaseInfo;
- (void) setDatabaseInfo: (PGTSDatabaseInfo *) anObject;
- (NSMutableDictionary *) deserializationDictionary;
- (void) setDeserializationDictionary: (NSMutableDictionary *) aDictionary;

- (void) setLogsQueries: (BOOL) aBool;
- (BOOL) logsQueries;

- (id <PGTSCertificateVerificationDelegate>) certificateVerificationDelegate;
- (void) setCertificateVerificationDelegate: (id <PGTSCertificateVerificationDelegate>) anObject;

- (BOOL) connectingAsync;
@end


@interface PGTSConnection (StatusMethods)
- (BOOL) connected;
- (NSString *) databaseName;
- (NSString *) user;
- (NSString *) password;
- (NSString *) host;
- (long) port;
- (NSString *) commandLineOptions;
- (ConnStatusType) connectionStatus;
- (PGTransactionStatusType) transactionStatus;
- (PGConnectionErrorCode) errorCode;
- (NSString *) statusOfParameter: (NSString *) parameterName;
- (int) protocolVersion;
- (int) serverVersion;
- (NSString *) errorMessage;
- (int) backendPID;
- (void *) sslStruct;
@end


@interface PGTSConnection (TransactionHandling)
- (BOOL) beginTransaction;
- (BOOL) commitTransaction;
- (BOOL) rollbackTransaction;
- (BOOL) rollbackToSavepointNamed: (NSString *) aName;
- (BOOL) savepointNamed: (NSString *) aName;
@end


@interface PGTSConnection (QueriesMainThread)

- (PGTSResultSet *) executeQuery: (NSString *) queryString;
- (PGTSResultSet *) executeQuery: (NSString *) queryString parameterArray: (NSArray *) parameters;
- (PGTSResultSet *) executeQuery: (NSString *) queryString parameters: (id) p1, ...;
- (PGTSResultSet *) executePrepareQuery: (NSString *) queryString name: (NSString *) aName;
- (PGTSResultSet *) executePrepareQuery: (NSString *) queryString name: (NSString *) aName 
                         parameterTypes: (Oid *) types;
- (PGTSResultSet *) executePreparedQuery: (NSString *) aName;
- (PGTSResultSet *) executePreparedQuery: (NSString *) aName parameters: (id) p1, ...;
- (PGTSResultSet *) executePreparedQuery: (NSString *) aName parameterArray: (NSArray *) parameters;
- (PGTSResultSet *) executeCopyData: (NSData *) data;
- (PGTSResultSet *) executeCopyData: (NSData *) data packetSize: (int) packetSize;
- (NSData *) executeReceiveCopyData;

- (int) sendQuery: (NSString *) queryString;
- (int) sendQuery: (NSString *) queryString parameterArray: (NSArray *) parameters;
- (int) sendQuery: (NSString *) queryString parameters: (id) p1, ...;
- (int) prepareQuery: (NSString *) queryString name: (NSString *) aName;
- (int) prepareQuery: (NSString *) queryString name: (NSString *) aName types: (Oid *) types;
- (int) sendPreparedQuery: (NSString *) aName parameters: (id) p1, ...;
- (int) sendPreparedQuery: (NSString *) aName parameterArray: (NSArray *) parameters;
- (void) sendCopyData: (NSData *) data;
- (void) sendCopyData: (NSData *) data packetSize: (int) packetSize;
- (void) receiveCopyData;

- (void) cancelCommand;

@end


@interface PGTSConnection (QueriesWorkerThread)
- (int) sendQuery2: (NSString *) queryString messageDelegate: (BOOL) messageDelegate;
- (int) sendQuery2: (NSString *) queryString parameterArray: (NSArray *) parameters
   messageDelegate: (BOOL) messageDelegate;
- (int) prepareQuery2: (NSString *) queryString name: (NSString *) aName
       parameterCount: (int) count parameterTypes: (Oid *) types messageDelegate: (BOOL) messageDelegate;
- (int) sendPreparedQuery2: (NSString *) aName parameterArray: (NSArray *) arguments 
           messageDelegate: (BOOL) messageDelegate;

- (int) sendCopyData2: (NSData *) data packetSize: (int) packetSize messageWhenDone: (BOOL) messageWhenDone;
- (int) endCopyAndAccept2: (BOOL) accept errorMessage: (NSString *) errorMessage messageWhenDone: (BOOL) messageWhenDone;
- (int) receiveRetainedCopyData2: (volatile NSData **) dataPtr;
- (void) receiveCopyDataAndSendToDelegate;

- (void) retrieveResultsAndSendToDelegate;
- (NSArray *) pendingResultSets;

@end


@interface PGTSConnection (NSCoding) <NSCoding>
@end
